return {
  "AlexandrosAlexiou/kotlin.nvim",
  ft = { "kotlin" },
  dependencies = {
    "mason.nvim",
    "mason-lspconfig.nvim",
    "trouble.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("kotlin").setup {
      root_markers = {
        "gradlew",
        ".git",
        "mvnw",
        "settings.gradle",
        "settings.gradle.kts",
      },
      jvm_args = { "-Xmx4g" },
      inlay_hints = {
        enabled = true,
        parameters = true,
        types_variable = true,
        function_return = true,
      },
      folding = { enabled = true },
    }
  end,
}
