local M = {}

-- Default configuration
local default_config = {
  -- API is served same-origin by the mdpubs web app under /api. For local dev
  -- this is the SvelteKit dev server; init.lua defaults prod to mdpubs.com/api.
  api_url = "http://localhost:5173/api",
  -- Public viewer base (mdpubs.com). Leave nil to derive it from api_url
  -- (strips a leading api. host or a trailing /api path). Override for
  -- self-hosted/custom domains.
  public_url = nil,
  api_key = "",
  watched_folders = {},
  auto_save = true,
  notifications = true,
  debug = false,
  -- Org publishing (mdpubs-company). A note is published under an org via
  -- `mdpubs-company: <slug>` frontmatter; that org can have a custom domain
  -- (e.g. docs.108labs.ai). Resolution is server-side and precedence is:
  --   frontmatter `mdpubs-company:`  ->  your company default  ->  personal.
  --
  -- Most users set a default in the mdpubs web UI and write nothing here. These
  -- options only help you AUTO-INSERT the frontmatter locally when it's missing:
  --
  --   default_company : slug to use for new notes that have no mdpubs-company.
  --   folder_companies : map of path prefix -> slug, e.g.
  --                     { ["~/notes/108labs"] = "108labs", ["~/acme"] = "acme" }
  --                     A matching prefix wins over default_company. Use the
  --                     value "none" to force a personal note under a path.
  --
  -- Leave both nil to never touch company frontmatter (recommended if you rely
  -- on the server-side company default).
  default_company = nil,
  folder_companies = nil,
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
-- strip a leading "api." host label (api.mdpubs.com -> mdpubs.com) AND a
-- trailing "/api" path segment (mdpubs.com/api -> mdpubs.com), since the API is
-- now served same-origin under /api rather than on a separate api. host.
function M.get_public_url()
  if config.public_url and config.public_url ~= "" then
    return (config.public_url:gsub("/$", ""))
  end
  local base = config.api_url:gsub("/$", "")
  -- //api.host -> //host  (legacy api.mdpubs.com and dev hosts)
  base = base:gsub("(//)api%.", "%1")
  -- host/api -> host  (new same-origin API base, e.g. mdpubs.com/api)
  base = base:gsub("/api$", "")
  return base
end

-- Resolve the mdpubs-company slug to use for a file at `path`, based on
-- folder_companies (longest matching prefix wins) then default_company. Returns
-- nil when neither is configured (leave company frontmatter untouched). Paths
-- and prefixes are expanded (~ -> $HOME) and normalised before comparison.
function M.get_company_for_path(path)
  local function expand(p)
    if not p or p == "" then return nil end
    return vim.fn.fnamemodify(vim.fn.expand(p), ":p"):gsub("/$", "")
  end

  local file = expand(path)
  if file and type(config.folder_companies) == "table" then
    local best_len, best_slug = -1, nil
    for prefix, slug in pairs(config.folder_companies) do
      local ep = expand(prefix)
      if ep and (file == ep or file:sub(1, #ep + 1) == ep .. "/") and #ep > best_len then
        best_len, best_slug = #ep, slug
      end
    end
    if best_slug then return best_slug end
  end

  return config.default_company
end

-- Get API headers
function M.get_api_headers()
  return {
    ["Content-Type"] = "application/json",
    ["X-API-Key"] = config.api_key,
  }
end

return M 