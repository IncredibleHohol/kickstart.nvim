-- Coding agents report when they work (bin/nvim-agent, called from agent hooks).
-- While an agent works in the project of this nvim, the Kotlin LSP server is paused (SIGSTOP),
-- so it does not re-analyze every change that the agent makes.
-- When the last agent stops, the server continues (SIGCONT) and handles all changes at once.
local M = {}

local holds = {} -- 'name:pid:session' -> { name = string, pid = number? }
local paused = {} -- server pid -> true
local timer -- while there are holds, it checks every 30 s that the agent processes still run

--- Returns the PIDs of the Kotlin LSP servers that this nvim started.
local function servers()
  return vim.tbl_filter(function(pid)
    local proc = vim.api.nvim_get_proc(pid)
    return proc ~= nil and proc.name == 'intellij-server'
  end, vim.api.nvim_get_proc_children(vim.fn.getpid()))
end

local check_agents

--- Pauses the servers while there are holds. Continues them when there are no holds.
local function apply()
  if next(holds) then
    for _, pid in ipairs(servers()) do
      if not paused[pid] and vim.uv.kill(pid, 'sigstop') == 0 then
        paused[pid] = true
      end
    end
    if not timer then
      timer = assert(vim.uv.new_timer())
      timer:start(30000, 30000, vim.schedule_wrap(check_agents))
    end
  else
    for _, pid in ipairs(servers()) do
      if paused[pid] then
        vim.uv.kill(pid, 'sigcont')
      end
    end
    paused = {}
    if timer then
      timer:close()
      timer = nil
    end
  end
  vim.cmd.redrawstatus()
end

--- Releases the holds of agents that exited without an idle call, for example after a crash or an interrupt.
check_agents = function()
  for key, hold in pairs(holds) do
    if hold.pid and not vim.uv.kill(hold.pid, 0) then
      holds[key] = nil
    end
  end
  apply()
end

--- Called by bin/nvim-agent. state is 'busy' or 'idle'. pid is the agent process, or 0 if the script did not find it.
--- busy holds the server only if the agent works in the project of this nvim. idle always releases.
function M.remote(state, name, pid, session, cwd)
  local key = name .. ':' .. pid .. ':' .. session
  if state == 'idle' then
    holds[key] = nil
  else
    local root = vim.uv.fs_realpath(vim.fn.getcwd())
    if cwd == root or vim.startswith(cwd, root .. '/') then
      holds[key] = { name = name, pid = pid > 0 and pid or nil }
    end
  end
  apply()
end

--- Returns the statusline text: the agents that hold the paused server, or ''.
function M.status()
  if not next(paused) then
    return ''
  end
  local names = {}
  for _, hold in pairs(holds) do
    if not vim.tbl_contains(names, hold.name) then
      names[#names + 1] = hold.name
    end
  end
  table.sort(names)
  return 'LSP paused: ' .. table.concat(names, ', ')
end

local group = vim.api.nvim_create_augroup('agent_hold', {})

-- A server that starts while an agent works is paused too.
vim.api.nvim_create_autocmd('LspAttach', {
  group = group,
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client.name == 'kotlin_lsp' and next(holds) then
      apply()
    end
  end,
})

-- A paused server cannot exit. Continue it before nvim exits.
vim.api.nvim_create_autocmd('VimLeavePre', {
  group = group,
  callback = function()
    holds = {}
    apply()
  end,
})

vim.api.nvim_create_user_command('KotlinLspResume', function()
  holds = {}
  apply()
end, { desc = 'Continue the Kotlin LSP server that coding agents paused' })

return M
