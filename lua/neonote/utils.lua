local M = {}

-- Log message if debug mode is enabled
function M.log(message)
	local config = require("neonote.config")
	if config.get("debug") then
		print("[NeoNote] " .. message)
	end
end

-- Show notification to user
function M.notify(message, level)
	local config = require("neonote.config")
	if config.get("notifications") then
		level = level or vim.log.levels.INFO
		vim.notify("[NeoNote] " .. message, level)
	end
end

-- Parse YAML frontmatter from content
function M.parse_frontmatter(content)
	local frontmatter = {}
	local body = content

	-- Check if content starts with ---
	if content:match("^---\n") then
		local frontmatter_end = content:find("\n---\n", 4)
		if frontmatter_end then
			local frontmatter_text = content:sub(4, frontmatter_end - 1)
			body = content:sub(frontmatter_end + 5) -- Skip the closing ---

			-- Simple YAML parsing for key: value pairs
			for line in frontmatter_text:gmatch("[^\r\n]+") do
				line = line:match("^%s*(.-)%s*$") -- trim whitespace
				if line ~= "" and not line:match("^#") then -- skip empty lines and comments
					-- Look for colon separator
					local colon_pos = line:find(":")
					if colon_pos then
						local key_part = line:sub(1, colon_pos - 1):match("^%s*(.-)%s*$")
						local value_part = line:sub(colon_pos + 1):match("^%s*(.-)%s*$")

						-- Remove quotes from key if present
						local key = key_part:match("^[\"'](.+)[\"']$") or key_part

						-- Handle value (keeping existing logic)
						local value = value_part or ""

						-- Handle quoted values
						if value:match('^".*"$') or value:match("^'.*'$") then
							value = value:sub(2, -2)
						end

						-- Convert numbers
						local num_value = tonumber(value)
						if num_value then
							value = num_value
						elseif value:lower() == "true" then
							value = true
						elseif value:lower() == "false" then
							value = false
						elseif value:lower() == "null" or value == "" then
							value = nil
						end

						frontmatter[key] = value
					end
				end
			end
		end
	end

	return frontmatter, body
end

-- Extract neonote ID from frontmatter
function M.extract_neonote_id(content)
	local start_marker = "---\n"
	local end_marker = "\n---\n"

	-- Check for frontmatter at the beginning of the file content
	if not content:match("^" .. start_marker) then
		return nil, false, content
	end

	local fm_start = #start_marker + 1
	local fm_end = content:find(end_marker, fm_start, true)

	if not fm_end then
		-- No closing frontmatter tag, treat as no frontmatter
		return nil, false, content
	end

	local frontmatter_text = content:sub(fm_start, fm_end - 1)
	local body = content:sub(fm_end + #end_marker)

	M.log("Frontmatter parsing debug:")
	M.log("  - Raw frontmatter:\n" .. frontmatter_text)

	-- Check for neonote field within the frontmatter
	-- First, check if the neonote field exists at all
	local has_neonote_field = frontmatter_text:match('"?neonote"?%s*:') ~= nil

	-- Then, try to extract a numeric ID from it
	local id_match = frontmatter_text:match('"?neonote"?%s*:%s*(%d+)')
	local neonote_id = nil

	if id_match then
		neonote_id = tonumber(id_match)
	end

	M.log("  - Parsed neonote value: " .. tostring(neonote_id))
	M.log("  - Has neonote field: " .. tostring(has_neonote_field))

	-- Return ID (number or nil), whether neonote field exists, and body
	return neonote_id, has_neonote_field, body
end

-- Update frontmatter with neonote ID
function M.update_frontmatter_id(content, note_id)
	local frontmatter, body = M.parse_frontmatter(content)

	-- Set the neonote ID
	frontmatter.neonote = note_id

	-- Rebuild the content with updated frontmatter
	local new_content = "---\n"

	-- Add neonote first
	new_content = new_content .. "neonote: " .. note_id .. "\n"

	-- Add other frontmatter fields (except neonote which we already added)
	for key, value in pairs(frontmatter) do
		if key ~= "neonote" then
			if type(value) == "string" and (value:match("%s") or value == "") then
				new_content = new_content .. key .. ': "' .. value .. '"\n'
			else
				new_content = new_content .. key .. ": " .. tostring(value) .. "\n"
			end
		end
	end

	new_content = new_content .. "---\n" .. body

	return new_content
end

-- Add frontmatter with neonote ID to content that doesn't have frontmatter
function M.add_frontmatter_id(content, note_id)
	local frontmatter = "---\nneonote: " .. note_id .. "\n---\n"
	return frontmatter .. content
end

-- Extract note ID from filename (legacy support)
function M.extract_note_id(filepath)
	local filename = vim.fn.fnamemodify(filepath, ":t:r") -- Get filename without extension
	local note_id = tonumber(filename)
	return note_id
end

-- Extract title from filepath and content
function M.extract_title(filepath, content)
	-- First try to get title from first line of content (if it starts with #)
	local _, body = M.parse_frontmatter(content)
	local first_line = body:match("^([^\r\n]*)")
	if first_line and first_line:match("^#%s+(.+)") then
		return first_line:match("^#%s+(.+)")
	end

	-- Fallback to filename without extension
	local filename = vim.fn.fnamemodify(filepath, ":t:r")
	return filename
end

-- Check if file is in watched folders (used only for creating new notes)
function M.is_file_in_watched_folders(filepath)
	local config = require("neonote.config")
	local watched_folders = config.get("watched_folders") or {}

	-- Expand ~ in filepath for comparison
	local expanded_filepath = vim.fn.expand(filepath)

	for _, folder in ipairs(watched_folders) do
		local expanded_folder = vim.fn.expand(folder)
		-- Check if file is under this folder
		if expanded_filepath:sub(1, #expanded_folder) == expanded_folder then
			return true
		end
	end

	return false
end

-- Read file content
function M.read_file(filepath)
	local file = io.open(filepath, "r")
	if not file then
		M.log("Could not open file: " .. filepath)
		return nil
	end

	local content = file:read("*all")
	file:close()
	return content
end

-- Write content to file
function M.write_file(filepath, content)
	local file = io.open(filepath, "w")
	if not file then
		M.log("Could not write to file: " .. filepath)
		return false
	end

	file:write(content)
	file:close()
	return true
end

-- Get file modification time
function M.get_file_mtime(filepath)
	local stat = vim.loop.fs_stat(filepath)
	return stat and stat.mtime.sec or 0
end

-- Check if a string is empty or nil
function M.is_empty(str)
	return not str or str == ""
end

-- Sanitize filename for creating new notes
function M.sanitize_filename(filename)
	-- Remove/replace invalid characters
	filename = filename:gsub('[<>:"/\\|?*]', "-")
	-- Remove leading/trailing whitespace
	filename = filename:match("^%s*(.-)%s*$")
	-- Limit length
	if #filename > 100 then
		filename = filename:sub(1, 100)
	end
	return filename
end

-- Parse response for error messages
function M.parse_error_response(response)
	if type(response) == "table" then
		if response.error then
			return response.error
		elseif response.message then
			return response.message
		end
	elseif type(response) == "string" then
		return response
	end
	return "Unknown error"
end

return M
