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
        require('custom.term_panel').shell()
      end,
      desc = 'Terminal tab',
    },
    {
      '<leader>aT',
      function()
        require('custom.term_panel').shell(true)
      end,
      desc = 'New terminal tab',
    },
  },
}
