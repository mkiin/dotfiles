local M = {}

local MARKDOWN_FILETYPES = {
	markdown = true,
	mdx = true,
	["markdown.mdx"] = true,
}

local function notify(msg, level)
	vim.notify("[mo] " .. msg, level or vim.log.levels.INFO)
end

local function check_binary()
	if vim.fn.executable("mo") == 0 then
		notify("mo binary not found in PATH (try: mise use -g aqua:k1LoW/mo)", vim.log.levels.ERROR)
		return false
	end
	return true
end

local function get_group()
	local root = vim.fs.root(0, { ".git" })
	if root then
		return vim.fs.basename(root), root
	end
	local cwd = vim.uv.cwd() or vim.fn.getcwd()
	return vim.fs.basename(cwd), cwd
end

local function parse_json(stdout)
	if not stdout or stdout == "" then
		return nil
	end
	local ok, data = pcall(vim.json.decode, stdout)
	if ok then
		return data
	end
	return nil
end

local function status_sync()
	local result = vim.system({ "mo", "--status", "--json" }, { text = true }):wait()
	if result.code ~= 0 then
		return nil
	end
	return parse_json(result.stdout)
end

function M.preview(group_override)
	if not check_binary() then
		return
	end

	local ft = vim.bo.filetype
	if not MARKDOWN_FILETYPES[ft] then
		notify("not a markdown buffer (filetype=" .. ft .. ")", vim.log.levels.WARN)
		return
	end

	local buf_path = vim.api.nvim_buf_get_name(0)
	local modified = vim.bo.modified
	local group = group_override or get_group()

	local use_stdin = buf_path == "" or modified
	local cmd = { "mo", "--json", "-t", group }
	local sys_opts = { text = true }

	if use_stdin then
		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
		sys_opts.stdin = table.concat(lines, "\n")
	else
		table.insert(cmd, buf_path)
	end

	vim.system(cmd, sys_opts, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				notify("failed: " .. (result.stderr or "unknown error"), vim.log.levels.ERROR)
				return
			end
			local data = parse_json(result.stdout)
			local url
			if data then
				if data.files and data.files[1] then
					url = data.files[1].url
				else
					url = data.url
				end
			end
			if url then
				notify("opened: " .. url)
			else
				notify("opened")
			end
		end)
	end)
end

local function fetch_existing_groups()
	local status = status_sync()
	local names = {}
	local seen = {}
	if status then
		for _, server in ipairs(status) do
			for _, g in ipairs(server.groups or {}) do
				if g.name and not seen[g.name] then
					seen[g.name] = true
					table.insert(names, g.name)
				end
			end
		end
	end
	table.sort(names)
	return names
end

function M.preview_with_group()
	if not check_binary() then
		return
	end

	local ft = vim.bo.filetype
	if not MARKDOWN_FILETYPES[ft] then
		notify("not a markdown buffer (filetype=" .. ft .. ")", vim.log.levels.WARN)
		return
	end

	local existing = fetch_existing_groups()

	_G._mo_group_complete = function(arg_lead)
		return vim.tbl_filter(function(g)
			return g:find(vim.pesc(arg_lead), 1, true) == 1
		end, existing)
	end

	local default_group = get_group()
	local group = vim.fn.input({
		prompt = "mo group: ",
		default = default_group,
		completion = "customlist,v:lua._mo_group_complete",
	})

	if group == nil or group == "" then
		notify("cancelled")
		return
	end

	M.preview(group)
end

function M.groups()
	if not check_binary() then
		return
	end
	local status = status_sync()
	if not status or #status == 0 then
		notify("no running mo server")
		return
	end
	local lines = {}
	for _, server in ipairs(status) do
		for _, g in ipairs(server.groups or {}) do
			local files = g.files or 0
			local patterns = g.patterns and #g.patterns or 0
			table.insert(lines, string.format("  %s: %d file(s), %d pattern(s)", g.name, files, patterns))
		end
	end
	if #lines == 0 then
		notify("no groups")
	else
		notify("groups:\n" .. table.concat(lines, "\n"))
	end
end

function M.watch_toggle()
	if not check_binary() then
		return
	end

	local root = vim.fs.root(0, { ".git" })
	if not root then
		notify("not in a git repository", vim.log.levels.WARN)
		return
	end
	local group = vim.fs.basename(root)
	local pattern = root .. "/**/*.md"

	local status = status_sync()
	local already_watching = false
	if status then
		for _, server in ipairs(status) do
			for _, g in ipairs(server.groups or {}) do
				if g.name == group then
					for _, p in ipairs(g.patterns or {}) do
						if p == pattern then
							already_watching = true
							break
						end
					end
				end
			end
		end
	end

	local cmd
	if already_watching then
		cmd = { "mo", "--unwatch", pattern, "-t", group }
	else
		cmd = { "mo", "--watch", pattern, "-t", group }
	end

	vim.system(cmd, { text = true }, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				notify("watch toggle failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
				return
			end
			if already_watching then
				notify("unwatched: " .. pattern)
			else
				notify("watching: " .. pattern)
			end
		end)
	end)
end

local function run_simple(args, desc)
	if not check_binary() then
		return
	end
	local cmd = { "mo" }
	vim.list_extend(cmd, args)
	vim.system(cmd, { text = true }, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				notify((desc or "command") .. " failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
			else
				notify(desc or "ok")
			end
		end)
	end)
end

function M.status()
	if not check_binary() then
		return
	end
	vim.system({ "mo", "--status" }, { text = true }, function(result)
		vim.schedule(function()
			local out = (result.stdout or "") .. (result.stderr or "")
			if out == "" then
				notify("no running mo server")
			else
				notify(out)
			end
		end)
	end)
end

function M.close()
	if not check_binary() then
		return
	end
	local buf_path = vim.api.nvim_buf_get_name(0)
	if buf_path == "" then
		notify("no file path for current buffer", vim.log.levels.WARN)
		return
	end
	local group = get_group()
	run_simple({ "--close", buf_path, "-t", group }, "closed")
end

function M.shutdown()
	run_simple({ "--shutdown" }, "shutdown")
end

function M.restart()
	run_simple({ "--restart" }, "restarted")
end

function M.clear()
	vim.ui.select({ "Yes", "No" }, { prompt = "Clear mo session?" }, function(choice)
		if choice == "Yes" then
			run_simple({ "--clear" }, "cleared")
		end
	end)
end

function M.open()
	if not check_binary() then
		return
	end
	local status = status_sync()
	if not status or #status == 0 then
		notify("no running mo server", vim.log.levels.WARN)
		return
	end
	local url = status[1].url
	if not url then
		notify("could not resolve mo url", vim.log.levels.WARN)
		return
	end
	vim.ui.open(url)
end

function M.setup()
	local subcmds = {
		preview = M.preview,
		["preview-group"] = M.preview_with_group,
		watch = M.watch_toggle,
		groups = M.groups,
		status = M.status,
		close = M.close,
		shutdown = M.shutdown,
		restart = M.restart,
		clear = M.clear,
		open = M.open,
	}
	vim.api.nvim_create_user_command("Mo", function(args)
		local sub = args.fargs[1] or "preview"
		local fn = subcmds[sub]
		if not fn then
			notify("unknown subcommand: " .. sub, vim.log.levels.ERROR)
			return
		end
		fn()
	end, {
		nargs = "?",
		complete = function(arg_lead)
			local keys = vim.tbl_keys(subcmds)
			table.sort(keys)
			return vim.tbl_filter(function(k)
				return k:find("^" .. vim.pesc(arg_lead)) ~= nil
			end, keys)
		end,
		desc = "mo: markdown viewer",
	})
end

return M
