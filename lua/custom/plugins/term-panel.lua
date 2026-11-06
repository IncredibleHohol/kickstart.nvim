-- Keymaps for the terminal panel at the bottom (lua/custom/term_panel.lua).
return {
  'term-panel',
  virtual = true,
  keys = {
    {
      '<leader>ao',
      function()
        require('custom.term_panel').toggle()
      end,
      desc = 'Toggle terminal panel',
    },
    {
      '<leader>aO',
      function()
        require('custom.term_panel').new('omp', { 'omp' })
      end,
      desc = 'New omp tab',
    },
    {
      '<leader>at',
      function()
        require('custom.term_panel').new('term', { vim.o.shell })
      end,
      desc = 'New terminal tab',
    },
  },
}
