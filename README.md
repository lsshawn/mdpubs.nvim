# MdPubs.nvim

MdPubs syncs your markdown notes from Neovim to MdPubs cloud, so your thoughts are always safe, organized, and accessible.

<!-- Optional: Add a cool GIF of the plugin in action here! -->

## Why You'll Love MdPubs

- **Effortless Syncing**: Just add `mdpubs:` to your file's frontmatter. The plugin handles the rest, automatically syncing on save.
- **Your Notes, Your Way**: No more rigid folder structures or naming conventions. Organize your markdown files however you like, anywhere on your system.
- **Never Lose a Thought**: With bi-directional sync, your notes are always up-to-date, whether you edit them locally in Neovim.

## Quick Start: Sync Your First Note in Minutes

Get up and running with MdPubs in three simple steps.

### 1. Install the Plugin

Use your favorite plugin manager. With `lazy.nvim`:

```lua
{
  "lsshawn/mdpubs.nvim",
  config = function()
    require("mdpubs").setup({
      -- Get your API key from https://mdpubs.com
      api_key = "your-api-key",
    })
  end,
}
```

*Don't have an account? [Sign up for MdPubs now!](https://mdpubs.com)*

### 2. Tag a Note for Syncing

Open any markdown (`.md`) file and add `mdpubs:` to its YAML frontmatter. If you don't have frontmatter, just add it to the top of the file:

```markdown
---
title: "My Brilliant Idea"
mdpubs:
---

This is where the magic happens.
```

### 3. Save and Sync!

Save the file (`:w`). That's it! MdPubs.nvim automatically:
1. Creates a new note in your MdPubs account.
2. Updates the frontmatter with the new note's unique ID.

Your file's frontmatter will now look like this, ready for future updates:

```markdown
---
title: "My Brilliant Idea"
mdpubs: 12345
---

This is where the magic happens.
```

Future saves will automatically sync your changes to the cloud.

## The Magic of Frontmatter

MdPubs uses a simple `mdpubs` key in your YAML frontmatter to manage everything.

- **To create a new note**: Leave the `mdpubs:` key blank.
  ```yaml
  ---
  mdpubs:
  ---
  ```
- **To link an existing note**: Use the note's ID. The plugin handles this for you automatically after the first sync.
  ```yaml
  ---
  mdpubs: 12345
  ---
  ```

You can also include these optional fields anywhere in your frontmatter to enhance your notes:

- **`mdpubs-tags`**: Add comma-separated tags to organize your notes
  ```yaml
  ---
  mdpubs: 12345
  mdpubs-tags: programming, lua, vim, notes
  ---
  ```

- **`mdpubs-is-public`**: Control the visibility of your notes. Your notes can be view publicly via GET 'http://api-mdpubs.com/public.notes/123456' without any API key.
  ```yaml
  ---
  mdpubs: 12345
  mdpubs-is-public: true
  ---
  ```

**Complete example** with all optional fields:
```yaml
---
title: "My Post"
mdpubs: 12345  
mdpubs-tags: project, work, important
mdpubs-is-public: false
---
```

Any `.md` file *without* the `mdpubs:` key is simply ignored, giving you full control over what you sync.

## Commands

Take control of your workflow with these powerful commands:

| Command | Description |
|---------|-------------|
| `:MdPubsSync` | Manually sync the current file with the MdPubs cloud. |
| `:MdPubsRefresh` | Pull the latest version of the note from the cloud, overwriting local changes. |
| `:MdPubsStatus` | Check your connection to the MdPubs API. |

### Recommended Keymaps

For an even smoother experience, add these keymaps to your Neovim config:

```lua
-- Sync the current note to the cloud
vim.keymap.set("n", "<leader>ns", ":MdPubsSync<CR>", { desc = "MdPubs: Sync note" })
-- Refresh the current note from the cloud
vim.keymap.set("n", "<leader>nr", ":MdPubsRefresh<CR>", { desc = "MdPubs: Refresh note" })
-- Check API connection status
vim.keymap.set("n", "<leader>nt", ":MdPubsStatus<CR>", { desc = "MdPubs: API Status" })
```

## Full Configuration

Customize MdPubs to fit your needs perfectly.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api_key` | string | `"https://api-mdpubs.com"` | Your personal API authentication key. |
| `auto_save` | boolean | `true` | Toggle automatic sync on file save. |
| `notifications` | boolean | `true` | Show success/error notifications. |

Here is an example `setup()` call with all options:
```lua
require("mdpubs").setup({
  api_key = "your-api-key",
  -- Enable automatic syncing on every save.
  auto_save = true,
  notifications = true,
})
```

## Troubleshooting

Running into issues? Here are a few things to check first.

- **File Not Syncing?**
  1. Ensure the file has a `.md` extension.
  2. Verify the `mdpubs:` key is present in the frontmatter.
  3. Check `:messages` for any errors from the plugin.
  4. Test your API connection with `:MdPubsStatus`.

- **API Connection Issues?**
  1. Double-check your `api_url` and `api_key` in your config.
  2. Ensure your machine can connect to the `api_url`.
  3. Check for firewall or network issues that might be blocking the connection.

- **Frontmatter Problems?**
  1. Make sure the frontmatter is at the very top of the file.
  2. Ensure it's valid YAML, enclosed by `---` on the lines before and after.

