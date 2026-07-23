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

- **`mdpubs-is-private`**: Control the visibility of your notes. Your notes can be view publicly via GET 'http://api.mdpubs.com/notes/123456' without any API key.Default to `false`.
  ```yaml
  ---
  mdpubs: 12345
  mdpubs-is-private: true
  ---
  ```

**Complete example** with all optional fields:
```yaml
---
title: "My Post"
mdpubs: 12345  
mdpubs-tags: project, work, important
mdpubs-is-private: false
---
```

Any `.md` file *without* the `mdpubs:` key is simply ignored, giving you full control over what you sync.

## Commands

Take control of your workflow with these powerful commands:

| Command | Description |
|---------|-------------|
| `:MdPubsSync` | Manually sync the current file with the MdPubs cloud. |
| `:MdPubsRefresh` | Pull the latest version of the note from the cloud, overwriting local changes. |
| `:MdPubsCreate` | Publish the current buffer as a new note and add the `mdpubs` frontmatter. |
| `:MdPubsOpen` | Open the current note's public page in your browser. Bound to `<leader>mo` in markdown buffers by default. |
| `:MdPubsDelete` | Delete the current note from the cloud. Prompts to confirm, then **comments out** the `mdpubs:` line in the frontmatter so the file stays local — uncomment it to re-publish. Use `:MdPubsDelete!` to skip the confirmation. |
| `:MdPubsAccount [slug]` | Set the `mdpubs-account:` frontmatter for the current note (see [Publishing under an account](#publishing-under-an-account-org--custom-domain)). `:MdPubsAccount 108labs` publishes under that org; `:MdPubsAccount none` forces a personal note; `:MdPubsAccount` with no argument removes the line so it falls back to your account default. |
| `:MdPubsStatus` | Check your connection to the MdPubs API. |

## Publishing under an account (org / custom domain)

If you belong to an MdPubs **account** (organization), you can publish notes under
it — and that account can have its own custom domain, e.g. `docs.108labs.ai`.

Which account a note belongs to is decided in this order:

1. **`mdpubs-account:` frontmatter** in the note (explicit, per-file):
   ```yaml
   ---
   mdpubs: V1StGXR8_Z5
   mdpubs-account: 108labs
   ---
   ```
2. **Your account default** (set once in the MdPubs web UI) — used when a note
   has no `mdpubs-account`. Most single-company users just set this and never
   touch frontmatter.
3. **Personal** — no account, if neither of the above applies. Use
   `mdpubs-account: none` to force a note personal even when you have a default.

You must be a member of the account you name, or the sync is rejected.

### Writing for multiple companies

Just set `mdpubs-account:` per file — one line switches which company (and which
custom domain) a note publishes to. To automate it, point folders at accounts:

```lua
require("mdpubs").setup({
  folder_accounts = {
    ["~/notes/108labs"] = "108labs",  -- notes here default to 108labs
    ["~/notes/acme"]    = "acme",
  },
  default_account = nil, -- optional fallback for everything else
})
```

Then `:MdPubsAccount` with no argument fills in the account for the current file
based on its folder. (These options only help you *insert* the frontmatter
locally; resolution itself always happens server-side.)

### Recommended Keymaps

`<leader>mo` (open the current note in the browser) is set automatically in
markdown buffers. For the rest, add these keymaps to your Neovim config:

```lua
-- Sync the current note to the cloud
vim.keymap.set("n", "<leader>ns", ":MdPubsSync<CR>", { desc = "MdPubs: Sync note" })
-- Refresh the current note from the cloud
vim.keymap.set("n", "<leader>nr", ":MdPubsRefresh<CR>", { desc = "MdPubs: Refresh note" })
-- Delete the current note from the cloud
vim.keymap.set("n", "<leader>nd", ":MdPubsDelete<CR>", { desc = "MdPubs: Delete note" })
-- Check API connection status
vim.keymap.set("n", "<leader>nt", ":MdPubsStatus<CR>", { desc = "MdPubs: API Status" })
```

## Full Configuration

Customize MdPubs to fit your needs perfectly.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api_key` | string | `"https://api.mdpubs.com"` | Your personal API authentication key. |
| `public_url` | string | derived from `api_url` | Public viewer base for `:MdPubsOpen` (e.g. `https://mdpubs.com`). Defaults to `api_url` with the leading `api.` removed; override for custom domains. |
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

