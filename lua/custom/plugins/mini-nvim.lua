return {
  "echasnovski/mini.nvim",
  event = "VeryLazy",
  version = false,
  config = function()
    -- to toggle comments just hit `gc`
    require("mini.comment").setup({
      options = {
        custom_commentstring = function()
          return vim.bo[0].filetype == "swift" and "// %s"
        end,
      },
      mappings = {
        comment_line = "gc",
      },
    })

    -- to quickly add/remove surrounding characters
    -- `sd<symbol>` to delete
    -- `sa<motion><symbol>` to add
    require("mini.surround").setup({
      mappings = {
        add = "sa",
        delete = "sd",
        find = "",           -- Find surrounding (to the right)
        find_left = "",      -- Find surrounding (to the left)
        highlight = "",      -- Highlight surrounding
        replace = "",        -- Replace surrounding
        update_n_lines = "", -- Update `n_lines`
        suffix_last = "",    -- Suffix to search with "prev" method
        suffix_next = "",    -- Suffix to search with "next" method
      },
    })

    -- this is very useful, by hitting `sj` you can split arguments into new lines (ctrl+m in Xcode)
    require("mini.splitjoin").setup({
      mappings = {
        toggle = "sj",
        split = "",
        join = "",
      },
    })

    -- recently, I stopped using it but it adds automatically closing brackets, quotes, etc.
    require("mini.pairs").setup({
      modes = { insert = true, command = false, terminal = false },
      mappings = { ["`"] = false },
    })

    local hipatterns = require("mini.hipatterns")
    hipatterns.setup({
      highlighters = {
        fixme     = { pattern = 'FIXME', group = 'MiniHipatternsFixme' },
        hack      = { pattern = 'HACK', group = 'MiniHipatternsHack' },
        todo      = { pattern = 'TODO', group = 'MiniHipatternsTodo' },
        note      = { pattern = 'NOTE', group = 'MiniHipatternsNote' },
        hex_color = hipatterns.gen_highlighter.hex_color(),
      }
    })

    -- MARK: fdas
    -- to easily move code around
    require("mini.move").setup({
      mappings = {
        left = "<A-h>",
        right = "<A-l>",
        down = "<A-j>",
        up = "<A-k>",
        line_left = "<A-h>",
        line_right = "<A-l>",
        line_down = "<A-j>",
        line_up = "<A-k>",
      },
    })
  end,
}
