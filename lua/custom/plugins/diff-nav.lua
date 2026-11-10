-- Keymaps for jumping between diff blocks (lua/custom/diff_nav.lua).
-- Buffers that gitsigns attaches to override these and call the same functions in diff mode.
return {
  'diff-nav',
  virtual = true,
  keys = {
    {
      ']c',
      function()
        require('custom.diff_nav').next_block()
      end,
      desc = 'Jump to next diff block',
    },
    {
      '[c',
      function()
        require('custom.diff_nav').prev_block()
      end,
      desc = 'Jump to previous diff block',
    },
  },
}
