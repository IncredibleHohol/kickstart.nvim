-- One split at the bottom of a tabpage for terminals. It shows one terminal at a time and a winbar tab for each terminal.
-- The terminals keep running when they are not shown. A tab closes when its process exits.
local M = {}

local tabs = {} -- { buf = number, name = string, title = string? }, in tab order
local last -- the buffer that the panel showed last
local claude -- the buffer of the Claude Code tab

-- Options of the panel window. A new window copies the options of the current window, and Diffview sets some of them.
-- A number, sign or fold column makes the terminal narrower. This breaks programs that fill the screen.
local win_opts = {
  winfixheight = true,
  number = false,
  relativenumber = false,
  signcolumn = 'no',
  foldcolumn = '0',
  diff = false,
  scrollbind = false,
  cursorbind = false,
}

local function index_of(buf)
  for i, tab in ipairs(tabs) do
    if tab.buf == buf then
      return i
    end
  end
end

--- Returns the panel windows of all tabpages.
local function panel_wins()
  return vim.tbl_filter(function(w)
    return vim.w[w].term_panel
  end, vim.api.nvim_list_wins())
end

--- Returns the panel window of the current tabpage, or nil.
local function panel()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.w[w].term_panel then
      return w
    end
  end
end

local function shown()
  local w = panel()
  return w and vim.api.nvim_win_get_buf(w)
end

local function render()
  for _, w in ipairs(panel_wins()) do
    local current = vim.api.nvim_win_get_buf(w)
    local parts = {}
    for i, tab in ipairs(tabs) do
      local label = tab.name
      if tab.title then
        -- Long titles get a limit, so that many tabs fit in the winbar.
        local title = vim.fn.strcharlen(tab.title) > 100 and vim.fn.strcharpart(tab.title, 0, 99) .. '…' or tab.title
        label = title:gsub('%%', '%%%%')
      end
      parts[#parts + 1] = ('%s %d:%s '):format(tab.buf == current and '%#TabLineSel#' or '%#TabLine#', i, label)
    end
    vim.wo[w].winbar = table.concat(parts) .. '%#TabLineFill#'
  end
end

local function enter()
  vim.api.nvim_set_current_win(panel())
  vim.cmd.startinsert()
end

local function set_win_opts(w)
  for name, value in pairs(win_opts) do
    -- vim.wo[w] also sets the global value when w is the current window.
    vim.api.nvim_set_option_value(name, value, { scope = 'local', win = w })
  end
end

--- Shows the terminal in the panel. Opens the panel when it is closed.
local function show(buf, focus)
  local w = panel()
  if w then
    vim.api.nvim_win_set_buf(w, buf)
  else
    w = vim.api.nvim_open_win(buf, false, { split = 'below', win = -1, height = math.floor(vim.o.lines * 0.4) })
    vim.w[w].term_panel = true
  end
  -- A new window copies the options of the current window. A buffer switch can restore the options of an older window. So set them again.
  set_win_opts(w)
  last = buf
  render()
  if focus then
    enter()
  end
end

local function hide()
  local w = panel()
  if w then
    vim.api.nvim_win_close(w, false)
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
  for _, w in ipairs(panel_wins()) do
    if vim.api.nvim_win_get_buf(w) == buf then
      if next then
        local focused = w == vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(w, next.buf)
        set_win_opts(w)
        if focused then
          enter()
        end
      else
        vim.api.nvim_win_close(w, false)
      end
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
  -- The program sets its terminal title with an OSC 0 or OSC 2 sequence.
  vim.api.nvim_create_autocmd('TermRequest', {
    buffer = buf,
    callback = function(ev)
      local title = ev.data.sequence:match '^\27%][02];(.+)'
      local i = index_of(buf)
      if title and i then
        tabs[i].title = title
        render()
      end
    end,
  })
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

--- Returns the buffer of a tab with this name, or nil. The shown tab wins over the other tabs.
local function find(name)
  local current = tabs[index_of(shown()) or 0]
  if current and current.name == name then
    return current.buf
  end
  for _, tab in ipairs(tabs) do
    if tab.name == name then
      return tab.buf
    end
  end
end

--- Shows the shell tab and focuses it. Starts the shell in a new tab when there is no shell tab, or when new is true.
function M.shell(new)
  local existing = not new and find 'term'
  if existing then
    show(existing, true)
    return
  end
  start('term', { vim.o.shell }, {}, true)
end

--- Hides the panel when it is open. Otherwise shows the last tab, or starts omp when there are no tabs.
function M.toggle()
  if panel() then
    hide()
  elseif last then
    show(last, true)
  else
    M.new('omp', { 'omp' })
  end
end

--- Closes the panel windows of all tabpages. The terminals keep running.
function M.close_all()
  for _, w in ipairs(panel_wins()) do
    vim.api.nvim_win_close(w, false)
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
    if claude and shown() == claude and vim.api.nvim_get_current_win() == panel() then
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
