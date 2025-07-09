local config = require("mdpubs.config")
local utils = require("mdpubs.utils")

local M = {}

-- Make HTTP request using curl
local function make_request(method, endpoint, data, files, callback)
	if type(files) == "function" then
		callback = files
		files = nil
	end
	if type(data) == "function" then
		callback = data
		data = nil
		files = nil
	end

	utils.log("--- Preparing request " .. method .. " " .. endpoint)
	local url = config.get_api_url(endpoint)
	local headers = config.get_api_headers()
	local has_files = files and not vim.tbl_isempty(files)

	-- Build curl command
	local cmd = { "curl", "-s", "-X", method }

	-- Let curl set the content type for multipart requests
	if method == "POST" or method == "PUT" then
		headers["Content-Type"] = nil
	end

	utils.log("Request headers: " .. vim.inspect(headers))

	-- Add headers
	for key, value in pairs(headers) do
		if value then
			table.insert(cmd, "-H")
			table.insert(cmd, key .. ": " .. value)
		end
	end

	-- Add data for POST/PUT requests
	if method == "POST" or method == "PUT" then
		-- Use multipart/form-data
		if data then
			for key, value in pairs(data) do
				if type(value) == "table" then
					for _, v in ipairs(value) do
						table.insert(cmd, "--form")
						table.insert(cmd, key .. "[]=" .. tostring(v))
					end
				elseif value ~= nil then
					table.insert(cmd, "--form")
					table.insert(cmd, key .. "=" .. tostring(value))
				end
			end
		end
		if has_files then
			for key, filepath in pairs(files) do
				-- key = original path from markdown, e.g., '../assets/image.png'
				-- filepath = absolute path on disk
				table.insert(cmd, "--form")
				-- Use 'files[]' to allow multiple files and pass the original path as 'filename'.
				-- This is more robust as some backends sanitize form field names containing paths.
				-- The filename is quoted to handle any special characters in the path.
				local escaped_key = key:gsub('"', '\\"')
				table.insert(cmd, string.format('files[]=@%s;filename="%s"', filepath, escaped_key))
			end
		end
	end

	-- Add URL
	table.insert(cmd, url)

	if data then
		-- Avoid logging huge content field
		local temp_data = vim.deepcopy(data)
		if temp_data.content then
			temp_data.content = string.format("<content %d bytes>", #temp_data.content)
		end
		utils.log("Request data: " .. vim.inspect(temp_data))
	end
	if has_files then
		utils.log("Request files: " .. vim.inspect(files))
	end

	utils.log("Full curl command: " .. table.concat(cmd, " "))

	-- Execute curl command
	vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_exit = function(_, exit_code)
			utils.log("Request exit code: " .. exit_code)
		end,
		on_stdout = function(_, data_lines)
			local response_text = table.concat(data_lines, "\n")
			utils.log("Response: " .. response_text)

			if response_text == "" then
				callback(false, "Empty response")
				return
			end

			-- Try to parse JSON response
			local success, response_data = pcall(vim.fn.json_decode, response_text)
			if success then
				if response_data.error then
					callback(false, response_data.error)
				else
					callback(true, response_data)
				end
			else
				-- If not JSON, return raw text
				callback(true, response_text)
			end
		end,
		on_stderr = function(_, err_lines)
			local error_text = table.concat(err_lines, "\n")
			if error_text ~= "" then
				utils.log("Request error: " .. error_text)
				callback(false, error_text)
			end
		end,
	})
end

-- Ping the API to check connection
function M.ping(callback)
	make_request("GET", "/ping", nil, callback)
end

-- Create a new note
function M.create_note(title, content, file_extension, additional_fields, files, callback)
	-- Handle optional arguments
	if type(files) == "function" then
		callback = files
		files = nil
	elseif type(additional_fields) == "function" then
		callback = additional_fields
		files = nil
		additional_fields = {}
	end

	local data = {
		title = title,
		content = content,
		file_extension = file_extension,
	}

	-- Add additional fields if present
	if additional_fields.tags then
		data.tags = additional_fields.tags
	end
	if additional_fields.isPrivate ~= nil then
		data.isPrivate = additional_fields.isPrivate
	end

	make_request("POST", "/notes", data, files, callback)
end

-- Update an existing note
function M.update_note(id, title, content, file_extension, additional_fields, files, callback)
	-- Handle optional arguments
	if type(files) == "function" then
		callback = files
		files = nil
	elseif type(additional_fields) == "function" then
		callback = additional_fields
		files = nil
		additional_fields = {}
	end

	local data = {
		title = title,
		content = content,
		file_extension = file_extension,
	}

	-- Add additional fields if present
	if additional_fields.tags then
		data.tags = additional_fields.tags
	end
	if additional_fields.isPrivate ~= nil then
		data.isPrivate = additional_fields.isPrivate
	end

	make_request("PUT", "/notes/" .. id, data, files, callback)
end

-- Get a note by ID
function M.get_note(id, version, callback)
	if type(version) == "function" then
		callback = version
		version = nil
	end

	local endpoint = "/notes/" .. id
	if version then
		endpoint = endpoint .. "?version=" .. tostring(version)
	end
	make_request("GET", endpoint, nil, callback)
end

-- Delete a note by ID
function M.delete_note(id, callback)
	make_request("DELETE", "/notes/" .. id, nil, callback)
end

-- Get all notes
function M.get_all_notes(callback)
	make_request("GET", "/notes", nil, callback)
end

return M
