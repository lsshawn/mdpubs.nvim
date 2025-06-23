# NeoNote.nvim

A Neovim plugin for seamless integration with your NeoNote API. Automatically sync your markdown notes between Neovim and your NeoNote server.

## Features

- 🚀 **Auto-sync**: Automatically save .md files to your NeoNote API on file save
- 📝 **Smart naming**: Use filename as note ID (e.g., `2.md` = note ID 2)
- 🔧 **Configurable**: Set API endpoint, key, and watched folders
- ➕ **Easy creation**: Commands to create new notes with auto-generated IDs
- 🔒 **Secure**: API key stored in your Neovim config

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "your-username/neonote.nvim",
  config = function()
    require("neonote").setup({
      api_url = "http://localhost:1323",
      api_key = "your-api-key-here",
      watched_folders = {
        "~/notes",
        "~/documents/notes",
      },
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "your-username/neonote.nvim",
  config = function()
    require("neonote").setup({
      api_url = "http://localhost:1323",
      api_key = "your-api-key-here",
      watched_folders = {
        "~/notes",
        "~/documents/notes",
      },
    })
  end,
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'your-username/neonote.nvim'
```

Then add to your `init.lua`:

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

```lua
require("neonote").setup({
  -- Your NeoNote API endpoint
  api_url = "http://localhost:1323",
  
  -- Your API key from NeoNote
  api_key = "your-64-character-api-key-here",
  
  -- Folders to watch for .md files (supports ~ expansion)
  watched_folders = {
    "~/notes",
    "~/documents/work-notes",
  },
  
  -- Optional: Auto-save on file write (default: true)
  auto_save = true,
  
  -- Optional: Show notifications (default: true)
  notifications = true,
  
  -- Optional: Debug mode (default: false)
  debug = false,
})
```

## Usage

### Auto-sync

Once configured, the plugin automatically syncs your notes:

1. Save any `.md` file in your watched folders
2. The plugin extracts the note ID from the filename (e.g., `15.md` → ID 15)
3. The note is automatically saved to your NeoNote API

### Manual Commands

```vim
" Create a new note with auto-generated ID
:NeoNoteNew

" Create a new note with specific title
:NeoNoteNew "My Important Note"

" Refresh the current note from API
:NeoNoteRefresh

" Force sync current note to API
:NeoNoteSync
```

### File Naming Convention

- Use the note ID as the filename: `{id}.md`
- Examples: `1.md`, `42.md`, `123.md`
- The plugin uses this ID to update the correct note in your API

### Creating New Notes

1. **Auto-generated ID**: Run `:NeoNoteNew` to create a new note with the next available ID
2. **Manual creation**: Create a file like `new-note.md`, add content, then run `:NeoNoteCreate` to upload and get an ID

## Getting Your API Key

1. Create a user in your NeoNote API:
   ```bash
   curl -X POST http://localhost:1323/api/users \
     -H "Content-Type: application/json" \
     -d '{"email": "your-email@example.com"}'
   ```

2. Copy the `api_key` from the response
3. Add it to your Neovim config

## Troubleshooting

### Enable Debug Mode

```lua
require("neonote").setup({
  -- ... other config ...
  debug = true,
})
```

This will show detailed logs of API requests and responses.

### Check API Connection

```vim
:NeoNoteStatus
```

### Common Issues

1. **"Invalid API key"**: Check your API key in the config
2. **"Note not found"**: Ensure the filename matches an existing note ID
3. **"Connection refused"**: Verify your API URL and that the server is running

## API Compatibility

This plugin is designed for the NeoNote API with the following endpoints:

- `POST /api/notes` - Create new note
- `PUT /api/notes/{id}` - Update existing note
- `GET /api/notes/{id}` - Get note by ID

## Contributing

Feel free to submit issues and pull requests!

## License

MIT 