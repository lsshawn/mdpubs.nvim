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
        
        -- Optional: Folders for creating new notes
        -- This is only used when creating new notes with :NeoNoteNew
        -- Syncing works for ANY .md file with 'neonote:' frontmatter
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
  -- watched_folders is optional
  watched_folders = {
    "~/notes",
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

-- 4. To sync files with the API, add frontmatter to your markdown files:
--    
--    Example new note (will create a new note on save):
--    ---
--    neonote:
--    title: "My Important Note"
--    ---
--    # My Important Note
--    
--    This is my note content...
--
--    Example existing note (will update note ID 123 on save):
--    ---
--    neonote: 123
--    title: "My Important Note" 
--    ---
--    # My Important Note
--    
--    This is my updated note content...
--
-- 5. Files can be ANYWHERE on your system - no need for specific folders!
-- 6. Files without 'neonote:' in frontmatter will be ignored (not synced)
-- 7. Use meaningful filenames like "meeting-notes.md" or "project-ideas.md"
-- 8. The plugin will automatically handle the API sync based on frontmatter! 