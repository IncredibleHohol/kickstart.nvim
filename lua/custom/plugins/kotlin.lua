local android_import_tasks = {
  ":app:assembleDebug",
  "createFullJarDebug",
  "createFullJarDebugTestFixtures",
  "createFullJarRelease",
  "createFullJarDev",
  ":app:processDevResources",
}

-- While the startup Gradle run is active, the Kotlin LSP start waits for it.
local preparing = false
local after_prepare = nil

local function find_gradle_root()
  local path = vim.api.nvim_buf_get_name(0)
  local start = path ~= "" and vim.fs.dirname(path) or vim.fn.getcwd()
  local root_file = vim.fs.find({ "settings.gradle", "settings.gradle.kts", "gradlew" }, {
    upward = true,
    path = start,
    type = "file",
  })[1]

  return root_file and vim.fs.dirname(root_file) or vim.fn.getcwd()
end

local function restart_kotlin_lsp()
  local clients = vim.lsp.get_clients({ name = "kotlin_lsp" })

  if #clients == 0 then
    vim.notify(
      "Kotlin LSP: no running client found. Open a Kotlin file to start the server.",
      vim.log.levels.INFO
    )
    return
  end

  vim.notify("Kotlin LSP: restarting workspace", vim.log.levels.INFO)
  vim.lsp.enable("kotlin_lsp", false)
  vim.defer_fn(function()
    vim.lsp.enable("kotlin_lsp", true)
    vim.notify("Kotlin LSP: restarted", vim.log.levels.INFO)
  end, 1000)
end

local function run_gradle_tasks(message, failure_message, tasks, on_done)
  local root = find_gradle_root()
  local gradlew = root .. "/gradlew"

  if vim.fn.executable(gradlew) ~= 1 then
    vim.notify("Kotlin LSP: gradlew is not executable in " .. root, vim.log.levels.ERROR)
    on_done(false)
    return
  end

  vim.notify(message, vim.log.levels.INFO)
  local cmd = { "./gradlew" }
  vim.list_extend(cmd, tasks)

  vim.system(cmd, { cwd = root, text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        local output = vim.trim((result.stderr or "") .. "\n" .. (result.stdout or ""))
        local lines = vim.split(output, "\n", { trimempty = true })
        local tail = vim.list_slice(lines, math.max(#lines - 19, 1), #lines)

        vim.notify(
          failure_message .. "\n" .. table.concat(tail, "\n"),
          vim.log.levels.ERROR
        )
      end
      on_done(result.code == 0)
    end)
  end)
end

local function restart_on_success(ok)
  if ok then
    restart_kotlin_lsp()
  end
end

return {
  "AlexandrosAlexiou/kotlin.nvim",
  ft = { "kotlin" },
  dependencies = {
    "mason.nvim",
    "mason-lspconfig.nvim",
    "trouble.nvim",
    "nvim-telescope/telescope.nvim",
  },
  -- Runs at startup, before any Kotlin file opens: in an Android project (cwd),
  -- build the artifacts the LSP import needs, then let the LSP start.
  init = function()
    if not vim.uv.fs_stat(find_gradle_root() .. "/app/src/main/AndroidManifest.xml") then
      return
    end

    preparing = true
    vim.schedule(function()
      run_gradle_tasks(
        "Kotlin LSP: preparing Android import artifacts, the server starts after that",
        "Kotlin LSP: Android import artifact preparation failed, the server starts anyway",
        android_import_tasks,
        function()
          preparing = false
          if after_prepare then
            after_prepare()
          end
        end
      )
    end)
  end,
  config = function()
    vim.env.KOTLIN_LSP_DIR = "/opt/homebrew/opt/kotlin-lsp/libexec"
    local kotlin = require("kotlin")

    vim.api.nvim_create_user_command("KotlinLspReloadWorkspace", restart_kotlin_lsp, {
      desc = "Restart the Kotlin LSP workspace",
    })

    vim.api.nvim_create_user_command("KotlinLspPrepareDebug", function()
      run_gradle_tasks(
        "Kotlin LSP: preparing debug artifacts",
        "Kotlin LSP: debug artifact preparation failed",
        {
          ":app:assembleDebug",
          "createFullJarDebug",
          "createFullJarDebugTestFixtures",
        },
        restart_on_success
      )
    end, {
      desc = "Build debug Android artifacts used by Kotlin LSP",
    })

    vim.api.nvim_create_user_command("KotlinLspPrepareAndroidImport", function()
      run_gradle_tasks(
        "Kotlin LSP: preparing Android import artifacts",
        "Kotlin LSP: Android import artifact preparation failed",
        android_import_tasks,
        restart_on_success
      )
    end, {
      desc = "Build Android artifacts requested by Kotlin LSP import",
    })

    local opts = {
      root_markers = {
        "gradlew",
        ".git",
        "mvnw",
        "settings.gradle",
        "settings.gradle.kts",
      },
      jdk_for_symbol_resolution = "/Applications/Android Studio.app/Contents/jbr/Contents/Home",
      jvm_args = { "-Xmx4g" },
      build_tool = "gradle",
      inlay_hints = {
        enabled = true,
        parameters = true,
        types_variable = true,
        function_return = true,
      },
      folding = { enabled = true },
    }

    if not preparing then
      kotlin.setup(opts)
      return
    end

    -- The FileType event that loaded this plugin is already gone, so start
    -- the LSP explicitly from a Kotlin buffer. vim.lsp.enable attaches the rest.
    vim.notify("Kotlin LSP: waiting for the Gradle preparation to finish", vim.log.levels.INFO)
    after_prepare = function()
      kotlin.setup(opts)
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "kotlin" then
          vim.api.nvim_buf_call(buf, function()
            kotlin.setup_kotlin_lsp(opts)
          end)
          return
        end
      end
    end
  end,
}
