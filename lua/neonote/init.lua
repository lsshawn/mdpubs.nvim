local config = require('neonote.config')
local api = require('neonote.api')
local utils = require('neonote.utils')

local M = {}

-- Setup function called by users
function M.setup(opts)
  config.setup(opts)
  
  -- Setup autocommands for auto-save
  if config.get('auto_save') then
    M.setup_autocommands()
  end
  
  -- Setup user commands
  M.setup_commands()
  
  utils.log("NeoNote plugin loaded successfully")
end

-- Setup autocommands for auto-save functionality
function M.setup_autocommands()
  local group = vim.api.nvim_create_augroup('NeoNote', { clear = true })
  
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    pattern = '*.md',
    callback = function(args)
      local filepath = args.file
      
      -- Check if file is in watched folders
      if utils.is_file_in_watched_folders(filepath) then
        M.sync_note(filepath)
      end
    end,
  })
end

-- Setup user commands
function M.setup_commands()
  vim.api.nvim_create_user_command('NeoNoteNew', function(opts)
    local title = opts.args and opts.args ~= '' and opts.args or nil
    M.create_new_note(title)
  end, { nargs = '?' })
  
  vim.api.nvim_create_user_command('NeoNoteSync', function()
    local filepath = vim.api.nvim_buf_get_name(0)
    if filepath and filepath ~= '' then
      M.sync_note(filepath)
    else
      utils.notify("No file to sync", vim.log.levels.WARN)
    end
  end, {})
  
  vim.api.nvim_create_user_command('NeoNoteRefresh', function()
    M.refresh_current_note()
  end, {})
  
  vim.api.nvim_create_user_command('NeoNoteStatus', function()
    M.check_status()
  end, {})
  
  vim.api.nvim_create_user_command('NeoNoteCreate', function()
    M.create_from_current_buffer()
  end, {})
end

-- Sync a note file to the API
function M.sync_note(filepath)
  if not filepath or filepath == '' then
    utils.notify("Invalid file path", vim.log.levels.ERROR)
    return
  end
  
  local note_id = utils.extract_note_id(filepath)
  if not note_id then
    utils.notify("Could not extract note ID from filename: " .. vim.fn.fnamemodify(filepath, ':t'), vim.log.levels.WARN)
    return
  end
  
  -- Read file content
  local content = utils.read_file(filepath)
  if not content then
    utils.notify("Could not read file: " .. filepath, vim.log.levels.ERROR)
    return
  end
  
  -- Extract title from filename or first line
  local title = utils.extract_title(filepath, content)
  
  utils.log("Syncing note ID " .. note_id .. " from " .. filepath)
  
  -- Try to update the note
  api.update_note(note_id, title, content, function(success, response)
    if success then
      utils.notify("Note " .. note_id .. " synced successfully")
      utils.log("Note " .. note_id .. " synced successfully")
    else
      utils.notify("Failed to sync note " .. note_id .. ": " .. (response or "Unknown error"), vim.log.levels.ERROR)
      utils.log("Failed to sync note " .. note_id .. ": " .. (response or "Unknown error"))
    end
  end)
end

-- Create a new note
function M.create_new_note(title)
  local default_title = title or "New Note"
  local content = "# " .. default_title .. "\n\n"
  
  api.create_note(default_title, content, function(success, response)
    if success and response then
      local note_id = response.id
      local watched_folders = config.get('watched_folders')
      
      if #watched_folders == 0 then
        utils.notify("No watched folders configured", vim.log.levels.WARN)
        return
      end
      
      -- Use first watched folder
      local folder = vim.fn.expand(watched_folders[1])
      local filepath = folder .. "/" .. note_id .. ".md"
      
      -- Create directory if it doesn't exist
      vim.fn.mkdir(vim.fn.fnamemodify(filepath, ':h'), 'p')
      
      -- Write content to file
      utils.write_file(filepath, content)
      
      -- Open the file
      vim.cmd('edit ' .. filepath)
      
      utils.notify("Created new note: " .. note_id .. ".md")
      utils.log("Created new note with ID " .. note_id)
    else
      utils.notify("Failed to create note: " .. (response or "Unknown error"), vim.log.levels.ERROR)
      utils.log("Failed to create note: " .. (response or "Unknown error"))
    end
  end)
end

-- Refresh current note from API
function M.refresh_current_note()
  local filepath = vim.api.nvim_buf_get_name(0)
  if not filepath or filepath == '' then
    utils.notify("No file open", vim.log.levels.WARN)
    return
  end
  
  local note_id = utils.extract_note_id(filepath)
  if not note_id then
    utils.notify("Current file is not a note", vim.log.levels.WARN)
    return
  end
  
  api.get_note(note_id, function(success, response)
    if success and response then
      local content = response.content or ""
      
      -- Replace buffer content
      local lines = vim.split(content, '\n')
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
      
      -- Mark buffer as not modified
      vim.api.nvim_buf_set_option(0, 'modified', false)
      
      utils.notify("Note " .. note_id .. " refreshed from API")
      utils.log("Note " .. note_id .. " refreshed from API")
    else
      utils.notify("Failed to refresh note " .. note_id .. ": " .. (response or "Unknown error"), vim.log.levels.ERROR)
      utils.log("Failed to refresh note " .. note_id .. ": " .. (response or "Unknown error"))
    end
  end)
end

-- Create note from current buffer content
function M.create_from_current_buffer()
  local filepath = vim.api.nvim_buf_get_name(0)
  if not filepath or filepath == '' then
    utils.notify("No file open", vim.log.levels.WARN)
    return
  end
  
  if not filepath:match('%.md$') then
    utils.notify("Current file is not a markdown file", vim.log.levels.WARN)
    return
  end
  
  -- Get buffer content
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines, '\n')
  
  -- Extract title from filename or content
  local title = utils.extract_title(filepath, content)
  
  api.create_note(title, content, function(success, response)
    if success and response then
      local note_id = response.id
      local dir = vim.fn.fnamemodify(filepath, ':h')
      local new_filepath = dir .. "/" .. note_id .. ".md"
      
      -- Rename the file
      vim.fn.rename(filepath, new_filepath)
      
      -- Update buffer name
      vim.api.nvim_buf_set_name(0, new_filepath)
      
      utils.notify("Created note with ID " .. note_id .. ", file renamed to " .. note_id .. ".md")
      utils.log("Created note with ID " .. note_id .. " from buffer")
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