return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "Trouble",
  event = { "BufReadPre", "BufNewFile" },
  keys = {
    { "<leader>tt", "<cmd>Trouble quickfix toggle<cr>", desc = "Toggle quickfix" },
    { "<leader>td", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics" },
    { "<leader>tD", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics" },
  },
  opts = {
    auto_close = false,
    auto_open = false,
    auto_preview = true,
    focus = true,
  },
  config = function(_, opts)
    local trouble = require("trouble")
    trouble.setup(opts)

    -- xcodebuild integration (v3 API)
    vim.api.nvim_create_autocmd("User", {
      pattern = { "XcodebuildBuildFinished", "XcodebuildTestsFinished" },
      callback = function(event)
        if event.data.cancelled then return end
        if event.data.success then
          trouble.close()
        elseif not event.data.failedCount or event.data.failedCount > 0 then
          if next(vim.fn.getqflist()) then
            trouble.open({ mode = "quickfix", focus = false })
          else
            trouble.close()
          end
          trouble.refresh()
        end
      end,
    })
  end,
}
