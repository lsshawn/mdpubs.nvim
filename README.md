# NeoNote.nvim

A Neovim plugin for seamless integration with NeoNote API, enabling automatic synchronization of markdown files with your note-taking backend.

## Features

- **Frontmatter-based syncing**: Use YAML frontmatter to manage note synchronization instead of rigid filename requirements
- **Auto-sync on save**: Automatically syncs any markdown file with `neonote:` frontmatter when saved
- **Smart note creation**: Create new notes directly from existing markdown files
- **Bi-directional sync**: Push local changes to API and pull updates from API

## Installation

### Using lazy.nvim

```lua
{
  "lsshawn/neonote.nvim",
  config = function()
    require("neonote").setup({
      api_url = "http://api-neonote.cupbots.com",
      api_key = "your-64-character-api-key-here",
      auto_save = true,
      notifications = true,
    })
  end,
}
```

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api_url` | string | `""` | Your NeoNote API endpoint URL |
| `api_key` | string | `""` | Your API authentication key |
| `auto_save` | boolean | `true` | Enable automatic sync on file save |
| `notifications` | boolean | `true` | Show success/error notifications |

## How It Works

### Frontmatter-Based Syncing

The plugin uses YAML frontmatter to manage note synchronization. Add a `neonote:` field to your markdown files:

#### New Note (will create a new note on save)
```markdown
---
title: "My Important Note"
neonote:
---

Your markdown content...
```

When you save this file, the plugin will:
1. Create a new note via the API
2. Update the frontmatter with the returned note ID
3. Future saves will update the existing note

#### Existing Note (will update note ID 123 on save)
```markdown
---
neonote: 123
title: "My Important Note" 
---
# My Important Note

This is my updated note content...
```

### File Organization

- Only `.md` files with `neonote:` frontmatter are processed
- Files without `neonote:` frontmatter are ignored (not synced)
- File naming doesn't matter as long as it's a `.md` file
- Files can be located **anywhere** on your system - no folder restrictions!

## Commands

| Command | Description |
|---------|-------------|
| `:NeoNoteSync` | Manually sync current file |
| `:NeoNoteRefresh` | Refresh current note from API |
| `:NeoNoteStatus` | Check API connection status |

## Keymaps (Optional)

Add these to your Neovim config:

```lua
vim.keymap.set("n", "<leader>ns", ":NeoNoteSync<CR>", { desc = "Sync current note" })
vim.keymap.set("n", "<leader>nr", ":NeoNoteRefresh<CR>", { desc = "Refresh note from API" })
vim.keymap.set("n", "<leader>nt", ":NeoNoteStatus<CR>", { desc = "Check API status" })
```

## Starting Fresh

1. Get your API key:
   ```bash
   curl -X POST https://api-neonote.cupbots.com \
     -H "Content-Type: application/json" \
     -d '{"email": "you@example.com"}'
   ```

2. Configure the plugin with your API key

3. Open a `.md` note and add `neonote: ` to its frontmatter:
   ```markdown
   ---
   neonote:
   ---
   # My First Note
   
   Hello, world!
   ```

4. Save the file - it will automatically create and get an ID

### Converting Existing Notes

For existing markdown files, use `:NeoNoteCreate` to add them to your synced collection:

1. Open an existing markdown file
2. Run `:NeoNoteCreate`
3. The plugin adds frontmatter and creates a new note
4. Save the file to persist changes

## API Requirements

Your NeoNote API should support these endpoints:

- `POST /api/notes` - Create new note
- `PUT /api/notes/{id}` - Update existing note  
- `GET /api/notes/{id}` - Get note by ID
- `GET /ping` - Health check

Authentication via `X-API-Key` header.

## Troubleshooting

### Files Not Syncing

1. Verify the file has `neonote:` in frontmatter
2. Check that the file has a `.md` extension
3. Enable debug mode and check `:messages`
4. Test API connection with `:NeoNoteStatus`

### API Connection Issues

1. Verify `api_url` and `api_key` in config
2. Test API directly with curl
3. Check firewall/network settings
4. Review debug logs for specific errors

### Frontmatter Parsing Issues

1. Ensure frontmatter uses valid YAML syntax
2. Check that frontmatter is at the very beginning of the file
3. Use `---` to delimit frontmatter blocks
4. Enable debug mode to see parsing results

