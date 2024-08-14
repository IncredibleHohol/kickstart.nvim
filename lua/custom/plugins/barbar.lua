return {
  'romgrk/barbar.nvim',
  dependencies = {
    'lewis6991/gitsigns.nvim',     -- OPTIONAL: for git status
    'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
  },
  init = function()
    local map = vim.api.nvim_set_keymap
    local opts = { noremap = true, silent = false }

    local function map_key(mode, key, command, description)
      vim.api.nvim_set_keymap(mode, key, command, { noremap = true, silent = false, desc = description })
    end

    -- Move to previous/next
    map('n', '<A-,>', '<Cmd>BufferPrevious<CR>', opts)
    map('n', '<A-.>', '<Cmd>BufferNext<CR>', opts)
    -- Re-order to previous/next
    map('n', '<A-<>', '<Cmd>BufferMovePrevious<CR>', opts)
    map('n', '<A->>', '<Cmd>BufferMoveNext<CR>', opts)
    -- Goto buffer in position...
    map('n', '<A-1>', '<Cmd>BufferGoto 1<CR>', opts)
    map('n', '<A-2>', '<Cmd>BufferGoto 2<CR>', opts)
    map('n', '<A-3>', '<Cmd>BufferGoto 3<CR>', opts)
    map('n', '<A-4>', '<Cmd>BufferGoto 4<CR>', opts)
    map('n', '<A-5>', '<Cmd>BufferGoto 5<CR>', opts)
    map('n', '<A-6>', '<Cmd>BufferGoto 6<CR>', opts)
    map('n', '<A-7>', '<Cmd>BufferGoto 7<CR>', opts)
    map('n', '<A-8>', '<Cmd>BufferGoto 8<CR>', opts)
    map('n', '<A-9>', '<Cmd>BufferGoto 9<CR>', opts)
    map('n', '<A-0>', '<Cmd>BufferLast<CR>', opts)
    -- Pin/unpin buffer
    map('n', '<A-p>', '<Cmd>BufferPin<CR>', opts)
    -- Close buffer
    map('n', '<A-c>', '<Cmd>BufferClose<CR>', opts)
    -- Sort automatically by...
    map_key('n', '<Space>bb', '<Cmd>BufferOrderByBufferNumber<CR>', "Order buffers by num[b]er")
    map_key('n', '<Space>bn', '<Cmd>BufferOrderByName<CR>', "Order buffers by [n]ame")
    map_key('n', '<Space>bd', '<Cmd>BufferOrderByDirectory<CR>', "Order buffers by [d]irectory")
    map_key('n', '<Space>bl', '<Cmd>BufferOrderByLanguage<CR>', "Order buffers by [l]anguage")
    map_key('n', '<Space>bw', '<Cmd>BufferOrderByWindowNumber<CR>', "Order buffers by [w]indow number")

    vim.g.barbar_auto_setup = false
  end,
  opts = {
    animation = true
  },
  version = '^1.0.0', -- optional: only update when a new 1.x version is released
}
