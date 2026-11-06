return {
  'sindrets/diffview.nvim',
  keys = {
    {
      '<leader>gd',
      function()
        if require('diffview.lib').get_current_view() then
          vim.cmd 'DiffviewClose'
        else
          vim.cmd 'DiffviewOpen'
        end
      end,
      desc = '[D]iffview: open or close',
    },
    { '<leader>gh', '<Cmd>DiffviewFileHistory %<CR>', desc = 'File [h]istory' },
  },
  opts = {
    -- the file list on the right, as the review plugin and nvim-tree show it
    file_panel = {
      win_config = { position = 'right', width = 50 },
    },
  },
}
