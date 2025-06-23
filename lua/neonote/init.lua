local config = require("neonote.config")
local api = require("neonote.api")
local utils = require("neonote.utils")

local M = {}

-- Setup function called by users
function M.setup(opts)
	config.setup(opts)

	utils.log("NeoNote setup started")
	utils.log("Configuration: " .. vim.inspect(config.get()))

	-- Setup autocommands for auto-save
	if config.get("auto_save") then
		utils.log("Auto-save is enabled, setting up autocommands")
		M.setup_autocommands()
	else
		utils.log("Auto-save is disabled, skipping autocommand setup")
	end

	-- Setup user commands
	M.setup_commands()

	utils.log("NeoNote plugin loaded successfully")
end

-- Setup autocommands for auto-save functionality
function M.setup_autocommands()
	local group = vim.api.nvim_create_augroup("NeoNote", { clear = true })

	utils.log("Setting up autocommands for auto-save")

	vim.api.nvim_create_autocmd("BufWritePost", {
		group = group,
		pattern = "*.md",
		callback = function(args)
			local filepath = args.file
			utils.log("BufWritePost triggered for: " .. filepath .. " (buf: " .. args.buf .. ")")

			-- Sync any .md file that has neonote frontmatter
			M.sync_note(filepath, args.buf)
		end,
	})

	utils.log("Autocommands set up successfully")
end

-- Setup user commands
function M.setup_commands()
	vim.api.nvim_create_user_command("NeoNoteNew", function(opts)
		local title = opts.args and opts.args ~= "" and opts.args or nil
		M.create_new_note(title)
	end, { nargs = "?" })

	vim.api.nvim_create_user_command("NeoNoteSync", function()
		local bufnr = vim.api.nvim_get_current_buf()
		local filepath = vim.api.nvim_buf_get_name(bufnr)
		if filepath and filepath ~= "" then
			M.sync_note(filepath, bufnr)
		else
			utils.notify("No file to sync", vim.log.levels.WARN)
		end
	end, {})

	vim.api.nvim_create_user_command("NeoNoteRefresh", function(opts)
		local version = opts.args and tonumber(opts.args) or nil
		M.refresh_current_note(version)
	end, { nargs = "?" })

	vim.api.nvim_create_user_command("NeoNoteStatus", function()
		M.check_status()
	end, {})

	vim.api.nvim_create_user_command("NeoNoteCreate", function()
		M.create_from_current_buffer()
	end, {})

	vim.api.nvim_create_user_command("NeoNoteReload", function()
		vim.cmd("edit!")
		utils.notify("Buffer reloaded from disk")
	end, {})
end

-- Sync a note file to the API
function M.sync_note(filepath, bufnr)
	if not filepath or filepath == "" then
		utils.notify("Invalid file path", vim.log.levels.ERROR)
		return
	end

	-- Read file content
	local content = utils.read_file(filepath)
	if not content then
		utils.notify("Could not read file: " .. filepath, vim.log.levels.ERROR)
		return
	end

	-- Extract neonote ID from frontmatter
	local note_id, has_neonote_field, body, additional_fields = utils.extract_neonote_id(content)

	utils.log("Sync analysis for " .. filepath .. ":")
	utils.log("  - Has neonote field: " .. tostring(has_neonote_field))
	utils.log("  - Note ID: " .. tostring(note_id))
	utils.log("  - Body length: " .. #body)
	utils.log("  - Additional fields: " .. vim.inspect(additional_fields))

	-- If no neonote field exists, skip syncing
	if not has_neonote_field then
		utils.log("File " .. filepath .. " has no 'neonote' field in frontmatter, skipping sync")
		return
	end

	-- Extract title from filename or first line
	local title = utils.extract_title(filepath, content)

	-- If neonote field exists but has no ID (empty, null, or missing), create new note
	if not note_id then
		utils.log("Creating new note for " .. filepath .. " (neonote field exists but no ID)")
		M.create_note_from_existing_file(filepath, title, bufnr)
		return
	end

	utils.log("Saving note ID " .. note_id .. " from " .. filepath .. "...")
	utils.notify("Saving note ID " .. note_id .. ".\nPlease keep this buffer open...")

	-- Try to update the existing note
	local file_extension = utils.get_file_extension(filepath)
	api.update_note(note_id, title, content, file_extension, additional_fields, function(success, response)
		if success then
			utils.notify("Note ID " .. note_id .. " synced successfully")
			utils.log("Note ID " .. note_id .. " synced successfully")
		else
			utils.notify(
				"Failed to sync note ID " .. note_id .. ":\n" .. (response or "Unknown error"),
				vim.log.levels.ERROR
			)
			utils.log("Failed to sync note ID " .. note_id .. ": " .. (response or "Unknown error"))
		end
	end)
end

-- Create a new note from an existing file that has neonote field but no ID
function M.create_note_from_existing_file(filepath, title, bufnr)
	utils.notify("Creating new note.\nPlease keep this buffer open...")

	-- Read current file content to send to API
	local current_content = utils.read_file(filepath)
	if not current_content then
		utils.notify("Failed to read file " .. filepath, vim.log.levels.ERROR)
		return
	end

	local file_extension = utils.get_file_extension(filepath)
	-- Create note with full content. The content sent to API won't have the ID yet.
	-- Extract additional fields from the current content for the API call
	local _, _, _, additional_fields = utils.extract_neonote_id(current_content)
	api.create_note(title, current_content, file_extension, additional_fields, function(success, response)
		if success and response then
			local note_id = response.id
			utils.log("Created new note with ID " .. note_id .. " for " .. filepath)

			-- Update the frontmatter with the new note ID
			local updated_content = utils.update_frontmatter_id(current_content, note_id)

			-- Write back to file
			if utils.write_file(filepath, updated_content) then
				if bufnr then
					local current_buf = vim.api.nvim_get_current_buf()
					if bufnr == current_buf then
						-- The updated file belongs to the currently active buffer.
						-- Schedule a reload.
						vim.schedule(function()
							vim.cmd("NeoNoteReload")
						end)
					else
						utils.log(
							"File " .. filepath .. " updated in background buffer " .. bufnr .. ". Not reloading."
						)
					end
				end

				utils.notify("Created new note " .. note_id .. " and updated frontmatter")
				utils.log("Updated frontmatter in " .. filepath .. " with note ID " .. note_id)
			else
				utils.notify(
					"Created note " .. note_id .. " but failed to update file frontmatter",
					vim.log.levels.WARN
				)
			end
		else
			utils.notify("Failed to create note: " .. (response or "Unknown error"), vim.log.levels.ERROR)
			utils.log("Failed to create note: " .. (response or "Unknown error"))
		end
	end)
end

-- Create a new note
function M.create_new_note(title)
	local default_title = title or "New Note"
	local body_content = "# " .. default_title .. "\n\n"

	-- Create a note with the initial body content
	local file_extension = "md" -- New notes are always markdown
	api.create_note(default_title, body_content, file_extension, {}, function(success, response)
		if success and response then
			local note_id = response.id
			local watched_folders = config.get("watched_folders")

			if #watched_folders == 0 then
				utils.notify("No watched folders configured", vim.log.levels.WARN)
				return
			end

			-- Use first watched folder
			local folder = vim.fn.expand(watched_folders[1])
			-- Use a meaningful filename instead of just the ID
			local filename = utils.sanitize_filename(default_title) .. ".md"
			local filepath = folder .. "/" .. filename

			-- Create directory if it doesn't exist
			vim.fn.mkdir(vim.fn.fnamemodify(filepath, ":h"), "p")

			-- Create content with frontmatter
			local full_content = utils.add_frontmatter_id(body_content, note_id)

			-- Write content to file
			utils.write_file(filepath, full_content)

			-- Open the file
			vim.cmd("edit " .. filepath)

			utils.notify("Created new note: " .. filename)
			utils.log("Created new note with ID " .. note_id .. " in file " .. filename)
		else
			utils.notify("Failed to create note: " .. (response or "Unknown error"), vim.log.levels.ERROR)
			utils.log("Failed to create note: " .. (response or "Unknown error"))
		end
	end)
end

-- Refresh current note from API
function M.refresh_current_note(version)
	local filepath = vim.api.nvim_buf_get_name(0)
	if not filepath or filepath == "" then
		utils.notify("No file open", vim.log.levels.WARN)
		return
	end

	-- Read current file content to get note ID from frontmatter
	local content = utils.read_file(filepath)
	if not content then
		utils.notify("Could not read current file", vim.log.levels.ERROR)
		return
	end

	local note_id, has_neonote_field, _, _ = utils.extract_neonote_id(content)
	if not has_neonote_field or not note_id then
		utils.notify("Current file is not a synced note (no neonote ID in frontmatter)", vim.log.levels.WARN)
		return
	end

	api.get_note(note_id, version, function(success, response)
		if success and response then
			local api_content = response.content or ""

			vim.schedule(function()
				-- Replace buffer content with content from the API
				local lines = vim.split(api_content, "\n")
				vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

				-- Mark buffer as not modified
				vim.api.nvim_buf_set_option(0, "modified", false)
			end)

			if version then
				utils.notify("Note " .. note_id .. " restored to version " .. version)
				utils.log("Note " .. note_id .. " restored to version " .. version)
			else
				utils.notify("Note " .. note_id .. " refreshed from API")
				utils.log("Note " .. note_id .. " refreshed from API")
			end
		else
			local error_message = "Failed to refresh note " .. note_id
			if version then
				error_message = "Failed to restore note " .. note_id .. " to version " .. version
			end
			utils.notify(error_message .. ": " .. utils.parse_error_response(response), vim.log.levels.ERROR)
			utils.log(error_message .. ": " .. utils.parse_error_response(response))
		end
	end)
end

-- Create note from current buffer content
function M.create_from_current_buffer()
	local filepath = vim.api.nvim_buf_get_name(0)
	if not filepath or filepath == "" then
		utils.notify("No file open", vim.log.levels.WARN)
		return
	end

	if not filepath:match("%.md$") then
		utils.notify("Current file is not a markdown file", vim.log.levels.WARN)
		return
	end

	-- Get buffer content
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local content = table.concat(lines, "\n")

	-- Check if it already has a neonote ID
	local existing_id, has_neonote_field, _, additional_fields = utils.extract_neonote_id(content)
	if has_neonote_field and existing_id then
		utils.notify("Current file already has a neonote ID: " .. existing_id, vim.log.levels.WARN)
		return
	end

	-- Extract title from filename or content
	local title = utils.extract_title(filepath, content)

	-- Create a note with the buffer's content
	local file_extension = utils.get_file_extension(filepath)
	api.create_note(title, content, file_extension, additional_fields, function(success, response)
		if success and response then
			local note_id = response.id

			-- Add frontmatter with neonote ID to current content
			local updated_content = utils.add_frontmatter_id(content, note_id)

			vim.schedule(function()
				-- Update buffer content
				local updated_lines = vim.split(updated_content, "\n")
				vim.api.nvim_buf_set_lines(0, 0, -1, false, updated_lines)

				-- Mark buffer as modified so user can save
				vim.api.nvim_buf_set_option(0, "modified", true)
			end)

			utils.notify("Created note with ID " .. note_id .. ", frontmatter added. Save to persist changes.")
			utils.log("Created note with ID " .. note_id .. " from buffer, added frontmatter")
		else
			utils.notify("Failed to create note: " .. (response or "Unknown error"), vim.log.levels.ERROR)
			utils.log("Failed to create note: " .. (response or "Unknown error"))
		end
	end)
end

-- Check API status
function M.check_status()
	api.ping(function(success, response)
		if success then
			utils.notify("API connection: OK")
			utils.log("API connection successful")
		else
			utils.notify("API connection failed: " .. (response or "Unknown error"), vim.log.levels.ERROR)
			utils.log("API connection failed: " .. (response or "Unknown error"))
		end
	end)
end

return M
