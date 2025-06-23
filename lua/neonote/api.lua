local config = require("neonote.config")
local utils = require("neonote.utils")

local M = {}

-- Make HTTP request using curl
local function make_request(method, endpoint, data, callback)
	local url = config.get_api_url(endpoint)
	local headers = config.get_api_headers()

	-- Build curl command
	local cmd = { "curl", "-s", "-X", method }

	-- Add headers
	for key, value in pairs(headers) do
		table.insert(cmd, "-H")
		table.insert(cmd, key .. ": " .. value)
	end

	-- Add data for POST/PUT requests
	if data and (method == "POST" or method == "PUT") then
		table.insert(cmd, "-d")
		table.insert(cmd, vim.fn.json_encode(data))
	end

	-- Add URL
	table.insert(cmd, url)

	utils.log("Making " .. method .. " request to " .. url)
	if data then
		utils.log("Request data: " .. vim.fn.json_encode(data))
	end

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
function M.create_note(title, content, file_extension, additional_fields, callback)
	-- Handle case where additional_fields might be a callback function (backward compatibility)
	if type(additional_fields) == "function" then
		callback = additional_fields
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
	if additional_fields.isPublic ~= nil then
		data.isPublic = additional_fields.isPublic
	end

	make_request("POST", "/notes", data, callback)
end

-- Update an existing note
function M.update_note(id, title, content, file_extension, additional_fields, callback)
	-- Handle case where additional_fields might be a callback function (backward compatibility)
	if type(additional_fields) == "function" then
		callback = additional_fields
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
	if additional_fields.isPublic ~= nil then
		data.isPublic = additional_fields.isPublic
	end

	make_request("PUT", "/notes/" .. id, data, callback)
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
