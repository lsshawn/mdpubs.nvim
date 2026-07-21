local config = require("mdpubs.config")
local api = require("mdpubs.api")
local utils = require("mdpubs.utils")

local M = {}

-- Setup function called by users
function M.setup(opts)
	opts = opts or {}
	if opts.api_url == nil then
		opts.api_url = "https://api.mdpubs.com"
	end

	config.setup(opts)

	utils.log("MdPubs setup started")
	utils.log("Configuration: " .. vim.inspect(config.get()))

	-- Setup autocommands for auto-save
	if config.get("auto_save") then
		utils.log("Auto-save is enabled, setting up autocommands")
		M.setup_autocommands()
	else
		utils.log("Auto-save is disabled, skipping autocommand setup")
	end

	-- Setup user commands
	M.setup_commands()

	utils.log("MdPubs plugin loaded successfully")
end

-- Setup autocommands for auto-save functionality
function M.setup_autocommands()
	local group = vim.api.nvim_create_augroup("MdPubs", { clear = true })

	utils.log("Setting up autocommands for auto-save")

	vim.api.nvim_create_autocmd("BufWritePost", {
		group = group,
		pattern = "*.md",
		callback = function(args)
			local filepath = args.file
			utils.log("BufWritePost triggered for: " .. filepath .. " (buf: " .. args.buf .. ")")

			-- Sync any .md file that has mdpubs frontmatter
			M.sync_note(filepath, args.buf)
		end,
	})

	utils.log("Autocommands set up successfully")
end

-- Setup user commands
function M.setup_commands()
	vim.api.nvim_create_user_command("MdPubsNew", function(opts)
		local title = opts.args and opts.args ~= "" and opts.args or nil
		M.create_new_note(title)
	end, { nargs = "?" })

	vim.api.nvim_create_user_command("MdPubsSync", function()
		local bufnr = vim.api.nvim_get_current_buf()
		local filepath = vim.api.nvim_buf_get_name(bufnr)
		if filepath and filepath ~= "" then
			M.sync_note(filepath, bufnr)
		else
			utils.notify("No file to sync", vim.log.levels.WARN)
		end
	end, {})

	vim.api.nvim_create_user_command("MdPubsRefresh", function(opts)
		local version = opts.args and tonumber(opts.args) or nil
		M.refresh_current_note(version)
	end, { nargs = "?" })

	vim.api.nvim_create_user_command("MdPubsStatus", function()
		M.check_status()
	end, {})

	vim.api.nvim_create_user_command("MdPubsCreate", function()
		M.create_from_current_buffer()
	end, {})

	vim.api.nvim_create_user_command("MdPubsReload", function()
		vim.cmd("edit!")
		utils.notify("Buffer reloaded from disk")
	end, {})

	vim.api.nvim_create_user_command("MdPubsDelete", function(opts)
		M.delete_current_note(opts.bang)
	end, { bang = true })

	vim.api.nvim_create_user_command("MdPubsOpen", function()
		M.open_current_note()
	end, {})

	M.setup_keymaps()
end

-- Buffer-local keymaps for markdown files (so <leader>m* only binds where notes
-- live, and never shadows the user's global <leader>m elsewhere).
function M.setup_keymaps()
	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("MdPubsKeymaps", { clear = true }),
		pattern = "markdown",
		callback = function(args)
			vim.keymap.set("n", "<leader>mo", M.open_current_note, {
				buffer = args.buf,
				desc = "MdPubs: open current note in browser",
			})
		end,
	})
end

-- Sync a note file to the API
function M.sync_note(filepath, bufnr)
	if not filepath or filepath == "" then
		utils.notify("Invalid file path", vim.log.levels.ERROR)
		return
	end

	-- Read file content
	local content = utils.read_file(filepath)
	if not content then
		utils.notify("Could not read file: " .. filepath, vim.log.levels.ERROR)
		return
	end

	-- Extract mdpubs ID from frontmatter
	local note_id, has_mdpubs_field, body, additional_fields = utils.extract_mdpubs_id(content)

	utils.log("Sync analysis for " .. filepath .. ":")
	utils.log("  - Has mdpubs field: " .. tostring(has_mdpubs_field))
	utils.log("  - Note ID: " .. tostring(note_id))
	utils.log("  - Body length: " .. #body)
	utils.log("  - Additional fields: " .. vim.inspect(additional_fields))

	-- If no mdpubs field exists, skip syncing
	if not has_mdpubs_field then
		utils.log("File " .. filepath .. " has no 'mdpubs' field in frontmatter, skipping sync")
		return
	end

	-- Extract title from filename or first line
	local title = utils.extract_title(filepath, content)

	-- If mdpubs field exists but has no ID (empty, null, or missing), create new note
	if not note_id then
		utils.log("Creating new note for " .. filepath .. " (mdpubs field exists but no ID)")
		M.create_note_from_existing_file(filepath, title, bufnr)
		return
	end

	utils.log("Saving note ID " .. note_id .. " from " .. filepath .. "...")
	utils.notify("Saving note ID " .. note_id .. ".\nPlease keep this buffer open...")

	-- Find local files to upload
	local base_dir = vim.fn.fnamemodify(filepath, ":h")
	local files_to_upload = utils.find_local_file_paths(content, base_dir)

	-- Try to update the existing note
	local file_extension = utils.get_file_extension(filepath)
	api.update_note(
		note_id,
		title,
		content,
		file_extension,
		additional_fields,
		files_to_upload,
		function(success, response)
			if success then
				utils.notify("Note ID " .. note_id .. " synced successfully")
				utils.log("Note ID " .. note_id .. " synced successfully")
			else
				utils.notify(
					"Failed to sync note ID " .. note_id .. ":\n" .. (response or "Unknown error"),
					vim.log.levels.ERROR
				)
				utils.log("Failed to sync note ID " .. note_id .. ": " .. (response or "Unknown error"))
			end
		end
	)
end

-- Create a new note from an existing file that has mdpubs field but no ID
function M.create_note_from_existing_file(filepath, title, bufnr)
	utils.notify("Creating new note.\nPlease keep this buffer open...")

	-- Read current file content to send to API
	local current_content = utils.read_file(filepath)
	if not current_content then
		utils.notify("Failed to read file " .. filepath, vim.log.levels.ERROR)
		return
	end

	local file_extension = utils.get_file_extension(filepath)
	-- Create note with full content. The content sent to API won't have the ID yet.
	-- Extract additional fields from the current content for the API call
	local _, _, _, additional_fields = utils.extract_mdpubs_id(current_content)
	-- Find local files to upload
	local base_dir = vim.fn.fnamemodify(filepath, ":h")
	local files_to_upload = utils.find_local_file_paths(current_content, base_dir)
	api.create_note(
		title,
		current_content,
		file_extension,
		additional_fields,
		files_to_upload,
		function(success, response)
			if success and response then
				-- Stamp the unguessable publicId (not the enumerable integer id) into
				-- frontmatter. Fall back to response.id only if an older API build
				-- doesn't return publicId.
				local note_id = response.publicId or response.id
				utils.log("Created new note with ID " .. note_id .. " for " .. filepath)

				-- Update the frontmatter with the new note ID
				local updated_content = utils.update_frontmatter_id(current_content, note_id)

				-- Write back to file
				if utils.write_file(filepath, updated_content) then
					if bufnr then
						local current_buf = vim.api.nvim_get_current_buf()
						if bufnr == current_buf then
							-- The updated file belongs to the currently active buffer.
							-- Schedule a reload.
							vim.schedule(function()
								vim.cmd("MdPubsReload")
							end)
						else
							utils.log(
								"File " .. filepath .. " updated in background buffer " .. bufnr .. ". Not reloading."
							)
						end
					end

					utils.notify("Created new note " .. note_id .. " and updated frontmatter")
					utils.log("Updated frontmatter in " .. filepath .. " with note ID " .. note_id)
				else
					utils.notify(
						"Created note " .. note_id .. " but failed to update file frontmatter",
						vim.log.levels.WARN
					)
				end
			else
				utils.notify("Failed: " .. (response or "Unknown error"), vim.log.levels.ERROR)
				utils.log("Failed: " .. (response or "Unknown error"))
			end
		end
	)
end

-- Create a new note
function M.create_new_note(title)
	local default_title = title or "New Note"
	local body_content = "# " .. default_title .. "\n\n"

	-- Create a note with the initial body content
	local file_extension = "md" -- New notes are always markdown
	api.create_note(default_title, body_content, file_extension, {}, function(success, response)
		if success and response then
			-- Stamp the unguessable publicId, not the enumerable integer id.
			local note_id = response.publicId or response.id
			local watched_folders = config.get("watched_folders")

			if #watched_folders == 0 then
				utils.notify("No watched folders configured", vim.log.levels.WARN)
				return
			end

			-- Use first watched folder
			local folder = vim.fn.expand(watched_folders[1])
			-- Use a meaningful filename instead of just the ID
			local filename = utils.sanitize_filename(default_title) .. ".md"
			local filepath = folder .. "/" .. filename

			-- Create directory if it doesn't exist
			vim.fn.mkdir(vim.fn.fnamemodify(filepath, ":h"), "p")

			-- Create content with frontmatter
			local full_content = utils.add_frontmatter_id(body_content, note_id)

			-- Write content to file
			utils.write_file(filepath, full_content)

			-- Open the file
			vim.cmd("edit " .. filepath)

			utils.notify("Created new note: " .. filename)
			utils.log("Created new note with ID " .. note_id .. " in file " .. filename)
		else
			utils.notify("Failed: " .. (response or "Unknown error"), vim.log.levels.ERROR)
			utils.log("Failed: " .. (response or "Unknown error"))
		end
	end)
end

-- Refresh current note from API
function M.refresh_current_note(version)
	local filepath = vim.api.nvim_buf_get_name(0)
	if not filepath or filepath == "" then
		utils.notify("No file open", vim.log.levels.WARN)
		return
	end

	-- Read current file content to get note ID from frontmatter
	local content = utils.read_file(filepath)
	if not content then
		utils.notify("Could not read current file", vim.log.levels.ERROR)
		return
	end

	local note_id, has_mdpubs_field, _, _ = utils.extract_mdpubs_id(content)
	if not has_mdpubs_field or not note_id then
		utils.notify("Current file is not a synced note (no mdpubs ID in frontmatter)", vim.log.levels.WARN)
		return
	end

	api.get_note(note_id, version, function(success, response)
		if success and response then
			local api_content = response.content or ""

			vim.schedule(function()
				-- Replace buffer content with content from the API
				local lines = vim.split(api_content, "\n")
				vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

				-- Mark buffer as not modified
				vim.api.nvim_buf_set_option(0, "modified", false)
			end)

			if version then
				utils.notify("Note " .. note_id .. " restored to version " .. version)
				utils.log("Note " .. note_id .. " restored to version " .. version)
			else
				utils.notify("Note " .. note_id .. " refreshed from API")
				utils.log("Note " .. note_id .. " refreshed from API")
			end
		else
			local error_message = "Failed to refresh note " .. note_id
			if version then
				error_message = "Failed to restore note " .. note_id .. " to version " .. version
			end
			utils.notify(error_message .. ": " .. utils.parse_error_response(response), vim.log.levels.ERROR)
			utils.log(error_message .. ": " .. utils.parse_error_response(response))
		end
	end)
end

-- Create note from current buffer content
function M.create_from_current_buffer()
	local filepath = vim.api.nvim_buf_get_name(0)
	if not filepath or filepath == "" then
		utils.notify("No file open", vim.log.levels.WARN)
		return
	end

	if not filepath:match("%.md$") then
		utils.notify("Current file is not a markdown file", vim.log.levels.WARN)
		return
	end

	-- Get buffer content
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local content = table.concat(lines, "\n")

	-- Check if it already has a mdpubs ID
	local existing_id, has_mdpubs_field, _, additional_fields = utils.extract_mdpubs_id(content)
	if has_mdpubs_field and existing_id then
		utils.notify("Current file already has a mdpubs ID: " .. existing_id, vim.log.levels.WARN)
		return
	end

	-- Extract title from filename or content
	local title = utils.extract_title(filepath, content)

	-- Find local files to upload
	local base_dir = vim.fn.fnamemodify(filepath, ":h")
	local files_to_upload = utils.find_local_file_paths(content, base_dir)

	-- Create a note with the buffer's content
	local file_extension = utils.get_file_extension(filepath)
	api.create_note(title, content, file_extension, additional_fields, files_to_upload, function(success, response)
		if success and response then
			-- Stamp the unguessable publicId, not the enumerable integer id.
			local note_id = response.publicId or response.id

			-- Add frontmatter with mdpubs ID to current content
			local updated_content = utils.add_frontmatter_id(content, note_id)

			vim.schedule(function()
				-- Update buffer content
				local updated_lines = vim.split(updated_content, "\n")
				vim.api.nvim_buf_set_lines(0, 0, -1, false, updated_lines)

				-- Mark buffer as modified so user can save
				vim.api.nvim_buf_set_option(0, "modified", true)
			end)

			utils.notify("Created note with ID " .. note_id .. ", frontmatter added. Save to persist changes.")
			utils.log("Created note with ID " .. note_id .. " from buffer, added frontmatter")
		else
			utils.notify("Failed: " .. (response or "Unknown error"), vim.log.levels.ERROR)
			utils.log("Failed: " .. (response or "Unknown error"))
		end
	end)
end

-- Delete the current note from the API, then comment out the `mdpubs:` line in
-- the frontmatter so the file stays local and un-synced (uncomment to re-publish).
-- Open the current note's public page in the browser.
function M.open_current_note()
	local bufnr = vim.api.nvim_get_current_buf()
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	if not filepath or filepath == "" then
		utils.notify("No file open", vim.log.levels.WARN)
		return
	end

	-- Read from the buffer so unsaved edits (e.g. a just-added id) are honoured.
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local content = table.concat(lines, "\n")

	local note_id, has_mdpubs_field = utils.extract_mdpubs_id(content)
	if not has_mdpubs_field or not note_id then
		utils.notify(
			"Current file is not a published note yet (no mdpubs id). Sync it first.",
			vim.log.levels.WARN
		)
		return
	end

	local url = config.get_public_url() .. "/" .. note_id
	utils.notify("Opening " .. url)

	-- vim.ui.open (Neovim 0.10+) picks the right platform opener; fall back to
	-- xdg-open / open / start for older versions.
	if vim.ui and vim.ui.open then
		vim.ui.open(url)
	else
		local opener = (vim.fn.has("mac") == 1 and "open")
			or (vim.fn.has("win32") == 1 and "start")
			or "xdg-open"
		vim.fn.jobstart({ opener, url }, { detach = true })
	end
end

-- Pass bang=true (`:MdPubsDelete!`) to skip the confirmation prompt.
function M.delete_current_note(skip_confirm)
	local bufnr = vim.api.nvim_get_current_buf()
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	if not filepath or filepath == "" then
		utils.notify("No file open", vim.log.levels.WARN)
		return
	end

	-- Read from the buffer (may have unsaved edits) so we operate on what the user sees.
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local content = table.concat(lines, "\n")

	local note_id, has_mdpubs_field = utils.extract_mdpubs_id(content)
	if not has_mdpubs_field or not note_id then
		utils.notify("Current file is not a synced note (no mdpubs ID in frontmatter)", vim.log.levels.WARN)
		return
	end

	-- Comment out the mdpubs id line so the file is no longer synced, but the user
	-- can uncomment to re-publish later. `prefix` tailors the notification.
	local function clear_frontmatter_id(prefix)
		local current_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local current_content = table.concat(current_lines, "\n")
		local updated_content, changed = utils.comment_out_frontmatter_id(current_content)

		if changed then
			local updated_lines = vim.split(updated_content, "\n")
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, updated_lines)
			vim.api.nvim_buf_set_option(bufnr, "modified", true)
			utils.notify(
				prefix .. " Commented out `mdpubs:` in frontmatter — save to persist, uncomment to re-publish."
			)
		else
			utils.notify(prefix .. " (could not update frontmatter)", vim.log.levels.WARN)
		end
	end

	local function do_delete()
		utils.notify("Deleting note ID " .. note_id .. "...")
		api.delete_note(note_id, function(success, response)
			vim.schedule(function()
				if success then
					utils.log("Deleted note ID " .. note_id)
					clear_frontmatter_id("Deleted note " .. note_id .. ".")
					return
				end

				-- The note may have been deleted manually on the platform already —
				-- the API returns not-found / not-owned. Treat that as "already gone"
				-- and still clean up the local frontmatter rather than erroring.
				if utils.is_note_gone_error(response) then
					utils.log("Note ID " .. note_id .. " already gone on server; clearing frontmatter")
					clear_frontmatter_id("Note " .. note_id .. " was already deleted on mdpubs.")
					return
				end

				utils.notify(
					"Failed to delete note ID " .. note_id .. ":\n" .. utils.parse_error_response(response),
					vim.log.levels.ERROR
				)
				utils.log("Failed to delete note ID " .. note_id .. ": " .. tostring(response))
			end)
		end)
	end

	if skip_confirm then
		do_delete()
		return
	end

	-- Confirm — deletion is destructive and outward-facing.
	local choice = vim.fn.confirm("Delete published note " .. note_id .. " from mdpubs?", "&Yes\n&No", 2)
	if choice == 1 then
		do_delete()
	else
		utils.notify("Delete cancelled")
	end
end

-- Check API status
function M.check_status()
	api.ping(function(success, response)
		if success then
			utils.notify("API connection: OK")
			utils.log("API connection successful")
		else
			utils.notify("API connection failed: " .. (response or "Unknown error"), vim.log.levels.ERROR)
			utils.log("API connection failed: " .. (response or "Unknown error"))
		end
	end)
end

return M
