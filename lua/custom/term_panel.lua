-- One split at the bottom for terminals. It shows one terminal at a time and a winbar tab for each terminal.
-- The terminals keep running when they are not shown. A tab closes when its process exits.
local M = {}

local tabs = {} -- { buf = number, name = string }, in tab order
local win -- the panel window
local last -- the buffer that the panel showed last
local claude -- the buffer of the Claude Code tab

local function index_of(buf)
  for i, tab in ipairs(tabs) do
    if tab.buf == buf then
      return i
    end
  end
end

local function is_open()
  return win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_tabpage(win) == vim.api.nvim_get_current_tabpage()
end

local function shown()
  return is_open() and vim.api.nvim_win_get_buf(win)
end

local function render()
  if not is_open() then
    return
  end
  local parts = {}
  for i, tab in ipairs(tabs) do
    parts[#parts + 1] = ('%s %d:%s '):format(tab.buf == shown() and '%#TabLineSel#' or '%#TabLine#', i, tab.name)
  end
  vim.wo[win].winbar = table.concat(parts) .. '%#TabLineFill#'
end

local function enter()
  vim.api.nvim_set_current_win(win)
  vim.cmd.startinsert()
end

--- Shows the terminal in the panel. Opens the panel when it is closed.
local function show(buf, focus)
  if is_open() then
    vim.api.nvim_win_set_buf(win, buf)
  else
    win = vim.api.nvim_open_win(buf, false, { split = 'below', win = -1, height = math.floor(vim.o.lines * 0.4) })
  end
  -- A buffer switch can restore the window options of an older window, so set them again.
  vim.wo[win].winfixheight = true
  last = buf
  render()
  if focus then
    enter()
  end
end

local function hide()
  if is_open() then
    vim.api.nvim_win_close(win, false)
  end
end

--- Removes the tab and deletes its buffer. The panel shows the next tab, or closes after the last tab.
local function remove(buf)
  local i = index_of(buf)
  if not i then
    return
  end
  table.remove(tabs, i)
  if buf == claude then
    claude = nil
  end
  local next = tabs[math.min(i, #tabs)]
  if last == buf then
    last = next and next.buf
  end
  if shown() == buf then
    if next then
      show(next.buf, vim.api.nvim_get_current_win() == win)
    else
      hide()
    end
  end
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  render()
end

--- Starts cmd in a new tab. Returns the buffer, or raises the jobstart error.
local function start(name, cmd, opts, focus)
  local buf = vim.api.nvim_create_buf(false, false)
  vim.bo[buf].bufhidden = 'hide'
  tabs[#tabs + 1] = { buf = buf, name = name }
  show(buf, false)
  opts.term = true
  opts.on_exit = function()
    vim.schedule(function()
      remove(buf)
    end)
  end
  -- nvim_buf_call adds a stack traceback to an error, so pcall runs inside the callback.
  local ok, err
  vim.api.nvim_buf_call(buf, function()
    ok, err = pcall(vim.fn.jobstart, cmd, opts)
  end)
  if not ok then
    remove(buf)
    error(err, 0)
  end
  for _, key in ipairs { { '<A-]>', 1, 'Next terminal tab' }, { '<A-[>', -1, 'Previous terminal tab' } } do
    vim.keymap.set({ 'n', 't' }, key[1], function()
      M.cycle(key[2])
    end, { buffer = buf, desc = key[3] })
  end
  for i = 1, 9 do
    vim.keymap.set({ 'n', 't' }, '<A-' .. i .. '>', function()
      M.select(i)
    end, { buffer = buf, desc = 'Terminal tab ' .. i })
  end
  if focus then
    enter()
  end
  return buf
end

--- Starts cmd (an argv list) in a new tab and focuses it.
function M.new(name, cmd)
  start(name, cmd, {}, true)
end

--- Hides the panel when it is open. Otherwise shows the last tab, or starts omp when there are no tabs.
function M.toggle()
  if is_open() then
    hide()
  elseif last then
    show(last, true)
  else
    M.new('omp', { 'omp' })
  end
end

--- Shows the tab that is step tabs after the shown tab. It wraps around.
function M.cycle(step)
  local i = index_of(shown())
  if i then
    show(tabs[(i - 1 + step) % #tabs + 1].buf, true)
  end
end

--- Shows tab i. It does nothing when there is no tab i.
function M.select(i)
  if tabs[i] then
    show(tabs[i].buf, true)
  end
end

--- A claudecode.nvim terminal provider: Claude Code runs in a tab of the panel.
M.claude_provider = {
  setup = function() end,
  open = function(cmd, env, config, focus)
    if claude then
      show(claude, focus ~= false)
    else
      claude = start('claude', require('claudecode.utils').parse_command(cmd), { env = env, cwd = config.cwd }, focus ~= false)
    end
  end,
  close = function()
    if claude then
      remove(claude)
    end
  end,
  simple_toggle = function(cmd, env, config)
    if claude and shown() == claude then
      hide()
    else
      M.claude_provider.open(cmd, env, config, true)
    end
  end,
  focus_toggle = function(cmd, env, config)
    if claude and shown() == claude and vim.api.nvim_get_current_win() == win then
      hide()
    else
      M.claude_provider.open(cmd, env, config, true)
    end
  end,
  get_active_bufnr = function()
    return claude
  end,
  is_available = function()
    return true
  end,
}

return M
