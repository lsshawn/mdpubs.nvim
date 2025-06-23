# NeoNote.nvim

A Neovim plugin for seamless integration with NeoNote API, enabling automatic synchronization of markdown files with your note-taking backend.

## Features

- **Frontmatter-based syncing**: Use YAML frontmatter to manage note synchronization instead of rigid filename requirements
- **Auto-sync on save**: Automatically syncs any markdown file with `neonote:` frontmatter when saved
- **Flexible file naming**: Use meaningful filenames like `meeting-notes.md` or `project-ideas.md`
- **Smart note creation**: Create new notes directly from existing markdown files
- **Bi-directional sync**: Push local changes to API and pull updates from API
- **Debug logging**: Built-in logging for troubleshooting
- **User-friendly notifications**: Clear feedback on sync status

## Installation

### Using lazy.nvim

```lua
{
  "your-username/neonote.nvim",
  config = function()
    require("neonote").setup({
      api_url = "http://localhost:1323",
      api_key = "your-64-character-api-key-here",
      watched_folders = {
        "~/notes",
        "~/documents/work",
        "~/personal/journal",
      },
      auto_save = true,
      notifications = true,
      debug = false,
    })
  end,
}
```

### Using other plugin managers

```lua
require("neonote").setup({
  api_url = "http://localhost:1323",
  api_key = "your-api-key-here",
  watched_folders = {
    "~/notes",
    "~/documents/notes",
  },
})
```

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api_url` | string | `""` | Your NeoNote API endpoint URL |
| `api_key` | string | `""` | Your API authentication key |
| `watched_folders` | table | `{}` | (Optional) Folders for creating new notes with `:NeoNoteNew` |
| `auto_save` | boolean | `true` | Enable automatic sync on file save |
| `notifications` | boolean | `true` | Show success/error notifications |
| `debug` | boolean | `false` | Enable debug logging |

## How It Works

### Frontmatter-Based Syncing

The plugin uses YAML frontmatter to manage note synchronization. Add a `neonote:` field to your markdown files:

#### New Note (will create a new note on save)
```markdown
---
neonote:
title: "My Important Note"
---
# My Important Note

This is my note content...
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

#### Regular Markdown (will be ignored)
```markdown
# Regular Note

This file has no neonote frontmatter, so it won't be synced.
```

### File Organization

- Use meaningful filenames: `meeting-notes.md`, `project-roadmap.md`, `daily-journal.md`
- Files without `neonote:` frontmatter are ignored (not synced)
- Files can be located **anywhere** on your system - no folder restrictions!
- Only `.md` files with `neonote:` frontmatter are processed

## Commands

| Command | Description |
|---------|-------------|
| `:NeoNoteNew [title]` | Create a new note with optional title |
| `:NeoNoteSync` | Manually sync current file |
| `:NeoNoteRefresh` | Refresh current note from API |
| `:NeoNoteCreate` | Convert current buffer to a synced note |
| `:NeoNoteStatus` | Check API connection status |

## Keymaps (Optional)

Add these to your Neovim config:

```lua
vim.keymap.set("n", "<leader>nn", ":NeoNoteNew<CR>", { desc = "Create new note" })
vim.keymap.set("n", "<leader>ns", ":NeoNoteSync<CR>", { desc = "Sync current note" })
vim.keymap.set("n", "<leader>nr", ":NeoNoteRefresh<CR>", { desc = "Refresh note from API" })
vim.keymap.set("n", "<leader>nt", ":NeoNoteStatus<CR>", { desc = "Check API status" })
vim.keymap.set("n", "<leader>nc", ":NeoNoteCreate<CR>", { desc = "Convert to synced note" })
```

## Debugging

### Enable Debug Mode

Set `debug = true` in your configuration:

```lua
require("neonote").setup({
  -- ... other options
  debug = true,
})
```

### View Debug Logs

Use `:messages` in Neovim to see debug output:

```
:messages
```

Debug logs include:
- Plugin loading status
- File sync operations
- API requests and responses
- Frontmatter parsing results
- Error details

## Workflow Examples

### Starting Fresh

1. Get your API key:
   ```bash
   curl -X POST http://localhost:1323/api/users \
     -H "Content-Type: application/json" \
     -d '{"email": "you@example.com"}'
   ```

2. Configure the plugin with your API key

3. Create a notes folder:
   ```bash
   mkdir -p ~/notes
   ```

4. Create your first note:
   ```bash
   nvim ~/notes/my-first-note.md
   ```

5. Add frontmatter and content:
   ```markdown
   ---
   neonote:
   ---
   # My First Note
   
   Hello, world!
   ```

6. Save the file - it will automatically sync and get an ID!

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

## License

MIT

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

Please ensure your changes maintain backward compatibility and include appropriate documentation updates. 
