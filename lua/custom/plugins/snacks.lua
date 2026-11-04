return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {},
  keys = {
    {
      "<leader>ao",
      function()
        Snacks.terminal.toggle("omp", { win = { position = "bottom", height = 0.4 } })
      end,
      desc = "Toggle omp",
    },
  },
}
