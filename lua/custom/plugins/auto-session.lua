return {
  "rmagatti/auto-session",
  config = function()
    local auto_session = require("auto-session")

    auto_session.setup({
      auto_restore_enabled = true,
      auto_session_suppress_dirs = { "~/Downloads", "~/Documents", "~/Desktop" },
      auto_save_enabled = true,
      -- A saved terminal window comes back as a plain window that the terminal panel does not know.
      pre_save_cmds = {
        function()
          require("custom.term_panel").close_all()
        end,
      },
    })
  end,
}
