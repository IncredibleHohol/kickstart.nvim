local progress_handle

return {
  'wojciech-kulik/xcodebuild.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
    'MunifTanjim/nui.nvim',
    'nvim-tree/nvim-tree.lua',         -- (optional) to manage project files
    'nvim-treesitter/nvim-treesitter', -- (optional) for Quick tests support (required Swift parser)
  },
  config = function()
    require('xcodebuild').setup {
      show_build_progress_bar = false,
      logs = {
        auto_open_on_success_tests = false,
        auto_open_on_failed_tests = false,
        auto_open_on_success_build = false,
        auto_open_on_failed_build = false,
        auto_focus = false,
        auto_close_on_app_launch = true,
        only_summary = true,
        notify = function(message, severity)
          local fidget = require 'fidget'
          if progress_handle then
            progress_handle.message = message
            if not message:find 'Loading' then
              progress_handle:finish()
              progress_handle = nil
              if vim.trim(message) ~= '' then
                fidget.notify(message, severity)
              end
            end
          else
            fidget.notify(message, severity)
          end
        end,
        notify_progress = function(message)
          local progress = require 'fidget.progress'

          if progress_handle then
            progress_handle.title = ''
            progress_handle.message = message
          else
            progress_handle = progress.handle.create {
              message = message,
              lsp_client = { name = 'xcodebuild.nvim' },
            }
          end
        end,
      },
      code_coverage = {
        enabled = true,
      },
    }

    -- stylua: ignore start
    vim.keymap.set("n", "<leader>X", "<cmd>XcodebuildPicker<cr>", { desc = "Show [X]codebuild Actions" })
    vim.keymap.set("n", "<leader>xf", "<cmd>XcodebuildProjectManager<cr>", { desc = "Show Project Manager Actions" })

    vim.keymap.set("n", "<leader>xb", "<cmd>XcodebuildBuild<cr>", { desc = "[B]uild Project" })
    vim.keymap.set("n", "<leader>xB", "<cmd>XcodebuildBuildForTesting<cr>", { desc = "[B]uild For Testing" })
    vim.keymap.set("n", "<leader>xr", "<cmd>XcodebuildBuildRun<cr>", { desc = "Build & [R]un Project" })

    vim.keymap.set("n", "<leader>xt", "<cmd>XcodebuildTest<cr>", { desc = "Run [T]ests" })
    vim.keymap.set("v", "<leader>xt", "<cmd>XcodebuildTestSelected<cr>", { desc = "Run Selected [T]ests" })
    vim.keymap.set("n", "<leader>xT", "<cmd>XcodebuildTestClass<cr>", { desc = "Run This [T]est Class" })

    vim.keymap.set("n", "<leader>xl", "<cmd>XcodebuildToggleLogs<cr>", { desc = "Toggle Xcodebuild [L]ogs" })
    vim.keymap.set("n", "<leader>xc", "<cmd>XcodebuildToggleCodeCoverage<cr>", { desc = "Toggle Code [C]overage" })
    vim.keymap.set("n", "<leader>xC", "<cmd>XcodebuildShowCodeCoverageReport<cr>",
      { desc = "Show Code [C]overage Report" })
    vim.keymap.set("n", "<leader>xe", "<cmd>XcodebuildTestExplorerToggle<cr>", { desc = "Toggle Test [E]xplorer" })
    vim.keymap.set("n", "<leader>xs", "<cmd>XcodebuildFailingSnapshots<cr>", { desc = "Show Failing [S]napshots" })

    vim.keymap.set("n", "<leader>xd", "<cmd>XcodebuildSelectDevice<cr>", { desc = "Select [D]evice" })
    vim.keymap.set("n", "<leader>xp", "<cmd>XcodebuildSelectTestPlan<cr>", { desc = "Select Test [P]lan" })
    vim.keymap.set("n", "<leader>xq", "<cmd>Telescope quickfix<cr>", { desc = "Show [Q]uickFix List" })

    vim.keymap.set("n", "<leader>xx", "<cmd>XcodebuildQuickfixLine<cr>", { desc = "Quickfi[x] Line" })
    vim.keymap.set("n", "<leader>xa", "<cmd>XcodebuildCodeActions<cr>", { desc = "Show Code [A]ctions" })
    vim.keymap.set("n", "<leader>xg", "<cmd>!pushd . && xcodegen; popd<cr>",
      { desc = "Run Xcode[g]en" })
  end,
}
