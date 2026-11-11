-- One split at the bottom of a tabpage for terminals. It shows one terminal at a time and a winbar tab for each terminal.
-- The terminals keep running when they are not shown. A tab closes when its process exits.
local M = {}

local tabs = {} -- { buf = number, name = string, title = string? }, in tab order
local last -- the buffer that the panel showed last

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

--- Starts cmd in a new tab and focuses it. Returns the buffer, or raises the jobstart error.
local function start(name, cmd)
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
  local opts = { term = true }
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
  enter()
  return buf
end

--- Reads the zsh history. Returns the commands, newest first, without duplicates.
local function zsh_history()
  local entries, entry = {}, nil
  for _, line in ipairs(vim.fn.readfile(vim.fn.expand '~/.zsh_history')) do
    -- zsh writes some bytes of non-ASCII characters as 0x83 and then the byte XOR 0x20.
    line = line:gsub('\131(.)', function(c)
      return string.char(bit.bxor(c:byte(), 32))
    end)
    entry = entry and entry .. '\n' .. line or line
    -- A line that ends with a backslash continues on the next line.
    if entry:sub(-1) == '\\' then
      entry = entry:sub(1, -2)
    else
      entries[#entries + 1] = entry
      entry = nil
    end
  end
  local commands, seen = {}, {}
  for i = #entries, 1, -1 do
    if not seen[entries[i]] then
      seen[entries[i]] = true
      commands[#commands + 1] = entries[i]
    end
  end
  return commands
end

--- Opens a Telescope picker with the zsh history. The selected command replaces the prompt line of the shell in buf.
local function pick_history(buf)
  local actions = require 'telescope.actions'
  require('telescope.pickers')
    .new({}, {
      prompt_title = 'Shell history',
      finder = require('telescope.finders').new_table {
        results = zsh_history(),
        entry_maker = function(command)
          local line = command:gsub('\n', '↵')
          return { value = command, display = line, ordinal = line }
        end,
      },
      sorter = require('telescope.config').values.generic_sorter {},
      attach_mappings = function(prompt_buf)
        actions.select_default:replace(function()
          local entry = require('telescope.actions.state').get_selected_entry()
          actions.close(prompt_buf)
          if entry then
            -- Ctrl-X Ctrl-K clears all lines of the command. A bracketed paste keeps the newlines of a multi-line command from running it.
            vim.api.nvim_chan_send(vim.bo[buf].channel, '\24\11\27[200~' .. entry.value .. '\27[201~')
          end
        end)
        -- Go back to Terminal mode in the shell after the picker closes.
        actions.close:enhance {
          post = function()
            vim.schedule(function()
              show(buf, true)
            end)
          end,
        }
        return true
      end,
    })
    :find()
end

--- Starts cmd (an argv list) in a new tab and focuses it.
function M.new(name, cmd)
  start(name, cmd)
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

--- Shows the tab with this name and focuses it. When the cursor is in that tab already, it hides the panel.
--- Starts cmd in a new tab when there is no tab with this name. Returns the buffer of a new tab, or nil.
function M.focus(name, cmd)
  local buf = find(name)
  if not buf then
    return start(name, cmd)
  end
  if buf == shown() and vim.api.nvim_get_current_win() == panel() then
    hide()
  else
    show(buf, true)
  end
end

--- Shows the shell tab and focuses it. Starts the shell in a new tab when there is no shell tab, or when new is true.
--- <C-r> in a new tab opens a Telescope picker with the zsh history.
function M.shell(new)
  local existing = not new and find 'term'
  if existing then
    show(existing, true)
    return
  end
  local buf = start('term', { vim.o.shell })
  vim.keymap.set('t', '<C-r>', function()
    pick_history(buf)
  end, { buffer = buf, desc = 'Search shell history' })
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

return M
