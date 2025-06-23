local M = {}

-- Log message if debug mode is enabled
function M.log(message)
  local config = require('neonote.config')
  if config.get('debug') then
    print("[NeoNote] " .. message)
  end
end

-- Show notification to user
function M.notify(message, level)
  local config = require('neonote.config')
  if config.get('notifications') then
    level = level or vim.log.levels.INFO
    vim.notify("[NeoNote] " .. message, level)
  end
end

-- Extract note ID from filename
function M.extract_note_id(filepath)
  local filename = vim.fn.fnamemodify(filepath, ':t:r') -- Get filename without extension
  local note_id = tonumber(filename)
  return note_id
end

-- Extract title from filepath and content
function M.extract_title(filepath, content)
  -- First try to get title from first line of content (if it starts with #)
  local first_line = content:match("^([^\r\n]*)")
  if first_line and first_line:match("^#%s+(.+)") then
    return first_line:match("^#%s+(.+)")
  end
  
  -- Fallback to filename without extension
  local filename = vim.fn.fnamemodify(filepath, ':t:r')
  return filename
end

-- Check if file is in watched folders
function M.is_file_in_watched_folders(filepath)
  local config = require('neonote.config')
  local watched_folders = config.get('watched_folders')
  
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
  local file = io.open(filepath, 'r')
  if not file then
    M.log("Could not open file: " .. filepath)
    return nil
  end
  
  local content = file:read('*all')
  file:close()
  return content
end

-- Write content to file
function M.write_file(filepath, content)
  local file = io.open(filepath, 'w')
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
  filename = filename:gsub('[<>:"/\\|?*]', '-')
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