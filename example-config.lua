-- Example MdPubs.nvim configuration
-- Place this in your Neovim config (init.lua or wherever you configure plugins)

-- For lazy.nvim users
require("lazy").setup({
	{
		"lsshawn/neonote.nvim",
		config = function()
			require("neonote").setup({
				-- Your MdPubs API endpoint
				api_url = "http://localhost:1323",
				-- Your API key (get this from https://neonote.sshawn.com)
				api_key = "your-64-character-api-key-here",
				-- Optional settings (these are the defaults)
				auto_save = true, -- Auto-save on file write
				notifications = true, -- Show success/error notifications
				debug = false, -- Enable debug logging
			})
		end,
	},
	-- ... your other plugins
})

-- Alternative configuration for other plugin managers
--[[
require("neonote").setup({
  api_url = "http://localhost:1323",
  api_key = "your-api-key-here",
  -- watched_folders is optional
  watched_folders = {
    "~/notes",
  },
})
--]]

-- Example keymaps (optional)
vim.keymap.set("n", "<leader>nn", ":MdPubsNew<CR>", { desc = "Create new note" })
vim.keymap.set("n", "<leader>ns", ":MdPubsSync<CR>", { desc = "Sync current note" })
vim.keymap.set("n", "<leader>nr", ":MdPubsRefresh<CR>", { desc = "Refresh note from API" })
vim.keymap.set("n", "<leader>nt", ":MdPubsStatus<CR>", { desc = "Check API status" })

-- Example workflow:
-- 1. Get your API key from 'https://neonote.sshawn.com'
-- 2. Copy the api_key from the response
-- 3. Update the api_key in your config above

-- 4. To sync files with the API, add `neonote` frontmatter to your markdown files:
--
--    Example new note (will create a new note on save):
--    ---
--    neonote:
--    title: "My Important Note"
--    ---
--
-- 5. Files can be ANYWHERE on your system - no need for specific folders!
-- 6. Files without 'neonote:' in frontmatter will be ignored (not synced)
-- 7. The plugin will automatically handle the API sync based on frontmatter!

