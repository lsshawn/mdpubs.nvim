local M = {}

-- Default configuration
local default_config = {
  api_url = "http://localhost:1323",
  api_key = "",
  watched_folders = {},
  auto_save = true,
  notifications = true,
  debug = false,
}

-- Current configuration
local config = {}

-- Setup configuration with user options
function M.setup(opts)
  opts = opts or {}
  
  -- Merge user options with defaults
  config = vim.tbl_deep_extend("force", default_config, opts)
  
  -- Validate configuration
  M.validate()
end

-- Validate configuration
function M.validate()
  local errors = {}
  
  if not config.api_url or config.api_url == "" then
    table.insert(errors, "api_url is required")
  end
  
  if not config.api_key or config.api_key == "" then
    table.insert(errors, "api_key is required")
  end
  
  if not config.watched_folders or type(config.watched_folders) ~= "table" then
    table.insert(errors, "watched_folders must be a table")
  end
  
  if #errors > 0 then
    error("NeoNote configuration errors:\n" .. table.concat(errors, "\n"))
  end
end

-- Get configuration value
function M.get(key)
  if key then
    return config[key]
  end
  return config
end

-- Set configuration value
function M.set(key, value)
  config[key] = value
end

-- Get API URL with endpoint
function M.get_api_url(endpoint)
  local base_url = config.api_url:gsub("/$", "")
  return base_url .. endpoint
end

-- Get API headers
function M.get_api_headers()
  return {
    ["Content-Type"] = "application/json",
    ["X-API-Key"] = config.api_key,
  }
end

return M 