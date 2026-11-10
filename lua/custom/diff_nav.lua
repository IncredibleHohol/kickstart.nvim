-- Jumps between blocks of changed lines in a diff window.
-- 'linematch' in 'diffopt' splits one visual block into several hunks, and the native ]c stops at each one.
-- Here, hunks that touch each other count as one block.
local M = {}

--- A line is in a block when the diff colours it, or when deleted lines of the other side sit above it.
local function changed(lnum)
  return vim.fn.diff_hlID(lnum, 1) ~= 0 or vim.fn.diff_filler(lnum) > 0
end

local function native(key)
  vim.cmd.normal { key, bang = true }
end

function M.next_block()
  if not vim.wo.diff then
    return
  end
  for _ = 1, vim.v.count1 do
    local saved = vim.api.nvim_win_get_cursor(0)
    local lnum, last = saved[1], vim.fn.line '$'
    -- go to the end of the block that holds the cursor, so ]c reaches the next block
    while lnum < last and changed(lnum) and changed(lnum + 1) do
      lnum = lnum + 1
    end
    vim.api.nvim_win_set_cursor(0, { lnum, 0 })
    native ']c'
    if vim.fn.line '.' == lnum then
      vim.api.nvim_win_set_cursor(0, saved)
      return
    end
  end
end

function M.prev_block()
  if not vim.wo.diff then
    return
  end
  for _ = 1, vim.v.count1 do
    local saved = vim.api.nvim_win_get_cursor(0)
    local lnum = saved[1]
    -- go to the start of the block that holds the cursor, so [c reaches the previous block
    while lnum > 1 and changed(lnum) and changed(lnum - 1) do
      lnum = lnum - 1
    end
    vim.api.nvim_win_set_cursor(0, { lnum, 0 })
    native '[c'
    local target = vim.fn.line '.'
    if target == lnum then
      vim.api.nvim_win_set_cursor(0, saved)
      return
    end
    -- [c reaches the last hunk of the previous block, so go to the start of that block
    while target > 1 and changed(target) and changed(target - 1) do
      target = target - 1
    end
    vim.api.nvim_win_set_cursor(0, { target, 0 })
  end
end

return M
