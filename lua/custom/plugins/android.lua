return {
  dir = '~/.config/android.nvim',
  config = function()
    require('android').setup {
      logs = {
        -- Build output and logcat open as a tab of the terminal panel (lua/custom/term_panel.lua).
        open = function(buf)
          require('custom.term_panel').attach('logs', buf, false)
        end,
        close = function(buf)
          require('custom.term_panel').detach(buf)
        end,
      },
    }
  end,
}
