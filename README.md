# NeoNote.nvim

NeoNote syncs your markdown notes from Neovim to NeoNote cloud, so your thoughts are always safe, organized, and accessible.

<!-- Optional: Add a cool GIF of the plugin in action here! -->

## Why You'll Love NeoNote

- **Effortless Syncing**: Just add `neonote:` to your file's frontmatter. The plugin handles the rest, automatically syncing on save.
- **Your Notes, Your Way**: No more rigid folder structures or naming conventions. Organize your markdown files however you like, anywhere on your system.
- **Never Lose a Thought**: With bi-directional sync, your notes are always up-to-date, whether you edit them locally in Neovim.

## Quick Start: Sync Your First Note in Minutes

Get up and running with NeoNote in three simple steps.

### 1. Install the Plugin

Use your favorite plugin manager. With `lazy.nvim`:

```lua
{
  "lsshawn/neonote.nvim",
  config = function()
    require("neonote").setup({
      -- Get your API key from your NeoNote account dashboard
      api_url = "https://api-neonote.cupbots.com",
      api_key = "your-64-character-api-key-here",
    })
  end,
}
```

*Don't have an account? [Sign up for NeoNote now!](https://api-neonote.cupbots.com)*

### 2. Tag a Note for Syncing

Open any markdown (`.md`) file and add `neonote:` to its YAML frontmatter. If you don't have frontmatter, just add it to the top of the file:

```markdown
---
title: "My Brilliant Idea"
neonote:
---

This is where the magic happens.
```

### 3. Save and Sync!

Save the file (`:w`). That's it! NeoNote.nvim automatically:
1. Creates a new note in your NeoNote account.
2. Updates the frontmatter with the new note's unique ID.

Your file's frontmatter will now look like this, ready for future updates:

```markdown
---
title: "My Brilliant Idea"
neonote: 12345
---

This is where the magic happens.
```

Future saves will automatically sync your changes to the cloud.

## The Magic of Frontmatter

NeoNote uses a simple `neonote` key in your YAML frontmatter to manage everything.

- **To create a new note**: Leave the `neonote:` key blank.
  ```yaml
  ---
  neonote:
  ---
  ```
- **To link an existing note**: Use the note's ID. The plugin handles this for you automatically after the first sync.
  ```yaml
  ---
  neonote: 12345
  ---
  ```

Any `.md` file *without* the `neonote:` key is simply ignored, giving you full control over what you sync.

## Commands

Take control of your workflow with these powerful commands:

| Command | Description |
|---------|-------------|
| `:NeoNoteSync` | Manually sync the current file with the NeoNote cloud. |
| `:NeoNoteRefresh` | Pull the latest version of the note from the cloud, overwriting local changes. |
| `:NeoNoteStatus` | Check your connection to the NeoNote API. |

### Recommended Keymaps

For an even smoother experience, add these keymaps to your Neovim config:

```lua
-- Sync the current note to the cloud
vim.keymap.set("n", "<leader>ns", ":NeoNoteSync<CR>", { desc = "NeoNote: Sync note" })
-- Refresh the current note from the cloud
vim.keymap.set("n", "<leader>nr", ":NeoNoteRefresh<CR>", { desc = "NeoNote: Refresh note" })
-- Check API connection status
vim.keymap.set("n", "<leader>nt", ":NeoNoteStatus<CR>", { desc = "NeoNote: API Status" })
```

## Full Configuration

Customize NeoNote to fit your needs perfectly.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api_url` | string | `""` | The endpoint for your NeoNote backend. |
| `api_key` | string | `""` | Your personal API authentication key. |
| `auto_save` | boolean | `true` | Toggle automatic sync on file save. |
| `notifications` | boolean | `true` | Show success/error notifications. |

Here is an example `setup()` call with all options:
```lua
require("neonote").setup({
  api_url = "https://api-neonote.cupbots.com",
  api_key = "your-64-character-api-key-here",
  -- Enable automatic syncing on every save.
  auto_save = true,
  notifications = true,
})
```

## Troubleshooting

Running into issues? Here are a few things to check first.

- **File Not Syncing?**
  1. Ensure the file has a `.md` extension.
  2. Verify the `neonote:` key is present in the frontmatter.
  3. Check `:messages` for any errors from the plugin.
  4. Test your API connection with `:NeoNoteStatus`.

- **API Connection Issues?**
  1. Double-check your `api_url` and `api_key` in your config.
  2. Ensure your machine can connect to the `api_url`.
  3. Check for firewall or network issues that might be blocking the connection.

- **Frontmatter Problems?**
  1. Make sure the frontmatter is at the very top of the file.
  2. Ensure it's valid YAML, enclosed by `---` on the lines before and after.

