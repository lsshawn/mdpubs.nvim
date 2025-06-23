-- Example NeoNote.nvim configuration
-- Place this in your Neovim config (init.lua or wherever you configure plugins)

-- For lazy.nvim users
require("lazy").setup({
  {
    "your-username/neonote.nvim",
    config = function()
      require("neonote").setup({
        -- Your NeoNote API endpoint
        api_url = "http://localhost:1323",
        
        -- Your API key (get this by creating a user in your API)
        api_key = "your-64-character-api-key-here",
        
        -- Folders to watch for .md files
        -- The plugin will auto-sync any .md files in these folders
        watched_folders = {
          "~/notes",              -- Main notes folder
          "~/documents/work",     -- Work notes
          "~/personal/journal",   -- Personal journal
        },
        
        -- Optional settings (these are the defaults)
        auto_save = true,         -- Auto-save on file write
        notifications = true,     -- Show success/error notifications
        debug = false,           -- Enable debug logging
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
  watched_folders = {
    "~/notes",
    "~/documents/notes",
  },
})
--]]

-- Example keymaps (optional)
vim.keymap.set("n", "<leader>nn", ":NeoNoteNew<CR>", { desc = "Create new note" })
vim.keymap.set("n", "<leader>ns", ":NeoNoteSync<CR>", { desc = "Sync current note" })
vim.keymap.set("n", "<leader>nr", ":NeoNoteRefresh<CR>", { desc = "Refresh note from API" })
vim.keymap.set("n", "<leader>nt", ":NeoNoteStatus<CR>", { desc = "Check API status" })

-- Example workflow:
-- 1. Get your API key:
--    curl -X POST http://localhost:1323/api/users -H "Content-Type: application/json" -d '{"email": "you@example.com"}'
-- 2. Copy the api_key from the response
-- 3. Update the api_key in your config above
-- 4. Create your notes folder: mkdir -p ~/notes
-- 5. Create a note: echo "# My First Note" > ~/notes/1.md
-- 6. Open in Neovim: nvim ~/notes/1.md
-- 7. Edit and save - it will auto-sync to your API! 