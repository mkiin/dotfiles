local restoreCursor = vim.api.nvim_create_augroup("restoreCursor", { clear = true })
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local ml = vim.fn.line([['"]])
    local eol = vim.fn.line("$")
    if 1 < ml and ml <= eol then
      vim.cmd.normal({ [[g`"]], bang = true })
    end
  end,
  group = restoreCursor,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function()
    local wh = vim.fn.winheight(0)
    local cl = vim.fn.line(".")
    if tb(vim.fn.empty(vim.bo.buftype)) and cl > wh / 3 * 2 then
      vim.cmd.normal({ "zz", bang = true })
      for _ = 0, (wh / 6) do
        vim.cmd.normal({ t("<C-y>"), bang = true })
      end
    end
  end,
  group = restoreCursor,
})

local augroup = vim.api.nvim_create_augroup("numbertoggle", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "InsertLeave", "CmdlineLeave", "WinEnter" }, {
  pattern = "*",
  group = augroup,
  callback = function()
    if vim.o.nu and vim.api.nvim_get_mode().mode ~= "i" then
      vim.opt.relativenumber = true
    end
  end,
})

vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "InsertEnter", "CmdlineEnter", "WinLeave" }, {
  pattern = "*",
  group = augroup,
  callback = function()
    if vim.o.nu then
      vim.opt.relativenumber = false
      vim.cmd("redraw")
    end
  end,
})

-- Idle timer: fires User IdleTick event every 1000ms while cursor is idle
local idle_timer_group = vim.api.nvim_create_augroup("idle_timer", { clear = true })
if _G.nvim_idle_timer then
  _G.nvim_idle_timer:stop()
  _G.nvim_idle_timer:close()
end
local idle_timer = assert(vim.uv.new_timer())
_G.nvim_idle_timer = idle_timer

local function stop_idle_timer()
  if idle_timer:is_active() then
    idle_timer:stop()
  end
end

local function start_idle_timer()
  stop_idle_timer()
  idle_timer:start(
    1000,
    1000,
    vim.schedule_wrap(function()
      if vim.fn.mode() ~= "c" and vim.api.nvim_get_mode().blocking == false then
        vim.api.nvim_exec_autocmds("User", { pattern = "IdleTick" })
      end
    end)
  )
end

-- Start timer on CursorHold
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  group = idle_timer_group,
  callback = start_idle_timer,
  desc = "Start idle timer on CursorHold",
})

-- Stop timer when cursor moves or mode changes
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertEnter", "InsertLeave", "CmdlineEnter" }, {
  pattern = "*",
  group = idle_timer_group,
  callback = stop_idle_timer,
  desc = "Stop idle timer on cursor move",
})

-- Check if file is modified on various events including IdleTick
local function checktime_if_safe()
  if vim.fn.mode() ~= "c" then
    vim.cmd.checktime()
  end
end

vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "CursorHold", "CursorHoldI", "WinEnter" }, {
  pattern = "*",
  callback = checktime_if_safe,
  desc = "check if file is modified",
})

vim.api.nvim_create_autocmd("User", {
  pattern = "IdleTick",
  callback = checktime_if_safe,
  desc = "check if file is modified on idle tick",
})

vim.api.nvim_create_autocmd("Filetype", {
  pattern = "*",
  callback = function()
    vim.opt_local.fo:remove({ "c", "r", "o" })
  end,
  desc = "disable comment in newline",
})

-- FileWritePre covers `:write other/path` from a buffer with a different name
vim.api.nvim_create_autocmd({ "BufWritePre", "FileWritePre" }, {
  pattern = "*",
  callback = function(args)
    -- URL-like names (oil://, oil-ssh://, scp://, ...) are handled by their own writers
    if args.match:match("^%a[%w+.-]*://") then
      return
    end
    vim.fn.mkdir(vim.fs.dirname(vim.fn.fnamemodify(args.match, ":p")), "p")
  end,
  desc = "create missing parent directories on write",
})

-- Neovim appends to its log file, so cap it between runs to avoid unbounded growth.
local LOG_SIZE_LIMIT = 10 * 1024 * 1024
for _, path in ipairs({
  vim.env.NVIM_LOG_FILE or vim.fs.joinpath(vim.fn.stdpath("log"), "nvim.log"),
}) do
  local stat = vim.uv.fs_stat(path)
  if stat and stat.size > LOG_SIZE_LIMIT then
    vim.uv.fs_unlink(path)
  end
end

vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "c:*",
  callback = function()
    local cmd = vim.fn.histget(":", -1)
    if cmd ~= nil and (cmd == "x" or cmd == "xa" or cmd:match("^w?q?a?!?$")) then
      vim.fn.histdel(":", -1)
    end
  end,
})

-- Close special buffers (quickfix, chat windows, etc.) when quitting the last normal window
vim.api.nvim_create_autocmd("QuitPre", {
  callback = function()
    if vim.bo.buftype ~= "" then
      return
    end
    local current_win = vim.api.nvim_get_current_win()
    local other_wins = vim.tbl_filter(function(win)
      return win ~= current_win
    end, vim.api.nvim_tabpage_list_wins(0))
    for _, win in ipairs(other_wins) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype == "" or vim.bo[buf].modified then
        return
      end
    end
    for _, win in ipairs(other_wins) do
      vim.api.nvim_win_close(win, false)
    end
  end,
})
