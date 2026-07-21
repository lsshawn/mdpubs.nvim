local M = {}

-- Default configuration
local default_config = {
  api_url = "http://localhost:1323",
  -- Public viewer base (mdpubs.com). Leave nil to derive it from api_url
  -- (api.mdpubs.com -> mdpubs.com). Override for self-hosted/custom domains.
  public_url = nil,
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
  
  -- watched_folders is now optional (only needed for creating new notes)
  if config.watched_folders and type(config.watched_folders) ~= "table" then
    table.insert(errors, "watched_folders must be a table if provided")
  end
  
  if #errors > 0 then
    error("MdPubs configuration errors:\n" .. table.concat(errors, "\n"))
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

-- Get the public viewer base URL (no trailing slash). Uses an explicit
-- public_url if set, otherwise derives it from api_url the way the CLI does:
-- strip a leading "api." host label (api.mdpubs.com -> mdpubs.com).
function M.get_public_url()
  if config.public_url and config.public_url ~= "" then
    return (config.public_url:gsub("/$", ""))
  end
  local base = config.api_url:gsub("/$", "")
  -- //api.host -> //host  (covers api.mdpubs.com and dev hosts alike)
  base = base:gsub("(//)api%.", "%1")
  return base
end

-- Get API headers
function M.get_api_headers()
  return {
    ["Content-Type"] = "application/json",
    ["X-API-Key"] = config.api_key,
  }
end

return M 