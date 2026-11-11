# Neovim config

My Neovim setup for Android (Kotlin) work on macOS. iOS (Swift) support is optional.
It started from [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim).

It works only on macOS on Apple Silicon. Some paths expect Homebrew in `/opt/homebrew`.

## Before you start

You need:

- [Homebrew](https://brew.sh).
- Android Studio in `/Applications/Android Studio.app`. Kotlin LSP uses its JBR.
- Access to the private `polarsteps/android.nvim` and `polarsteps/polarsteps-review-assistant` repos.

## 1. Install the tools

```sh
brew install neovim tree-sitter-cli ripgrep fd gh git-lfs imagemagick \
  jetbrains/utils/kotlin-lsp can1357/tap/omp
brew install --cask ghostty font-jetbrains-mono-nerd-font
curl -fsSL https://claude.ai/install.sh | bash

gh auth login
git lfs install
```

| Tool | Used for |
| :--- | :------- |
| `neovim` 0.12 or newer | The config and the `main` branch of nvim-treesitter |
| `tree-sitter-cli` | nvim-treesitter compiles the parsers with it |
| `ripgrep`, `fd` | Telescope search |
| `gh` | PR signs in the gutter, PR review |
| `git-lfs` | PR review |
| `imagemagick` | snacks.image converts images, for example in Diffview |
| `kotlin-lsp` | Kotlin LSP with kotlin.nvim |
| `claude` | A Claude Code tab of the terminal panel (`<leader>ac`) |
| `omp` | The first tab of the terminal panel (`<leader>ao`), PR review agents |
| Ghostty | A terminal with the kitty graphics protocol, for images |
| JetBrains Mono Nerd Font | Icons |

Homebrew installs the Xcode Command Line Tools. They give `git`, `make`, and `clang`.
Mason installs `lua_ls` and `stylua` when Neovim starts for the first time.

## 2. Set up Ghostty

Add these lines to the Ghostty config (`~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`):

```
font-family = "JetBrainsMono Nerd Font Mono"
macos-option-as-alt = true
```

`macos-option-as-alt` makes Option send Alt. The `<A-…>` keymaps need it: barbar buffers, mini.move, and the terminal panel tabs.

## 3. Clone the repos

Move an old config away first, if you have one:

```sh
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
```

Then clone the config and the two local plugins:

```sh
gh repo clone polarsteps/kickstart.nvim.android ~/.config/nvim
gh repo clone polarsteps/android.nvim ~/.config/android.nvim
gh repo clone polarsteps/polarsteps-review-assistant ~/StudioProjects/polarsteps-review-assistant
```

For the agent setup of the PR review, read the README of `polarsteps-review-assistant`.

## 4. Start Neovim

```sh
nvim
```

lazy.nvim installs the plugins. Mason installs the tools. nvim-treesitter compiles the parsers.
When this is done, restart Neovim and run:

```vim
:checkhealth kickstart
```

## Android projects

Start Neovim in the project root, the folder with `gradlew`.
If `app/src/main/AndroidManifest.xml` exists, the config runs Gradle tasks at startup.
Kotlin LSP starts after these tasks. The task list is in `lua/custom/plugins/kotlin.lua`.

Commands:

- `:KotlinLspPrepareDebug`: build the debug artifacts and restart Kotlin LSP.
- `:KotlinLspPrepareAndroidImport`: build the import artifacts and restart Kotlin LSP.
- `:KotlinLspReloadWorkspace`: restart Kotlin LSP.

## iOS projects (optional)

Skip this section if you do not work on iOS projects.

You need Xcode in `/Applications/Xcode.app`. Then install the tools:

```sh
sudo xcode-select -s /Applications/Xcode.app
xcodebuild -runFirstLaunch

brew install xcbeautify xcode-build-server xcp swiftlint jq coreutils pipx
pipx install pymobiledevice3
```

| Tool | Used for |
| :--- | :------- |
| `xcbeautify`, `xcode-build-server`, `xcp`, `jq`, `coreutils`, `pymobiledevice3` | xcodebuild.nvim: build, test, debug, project files, physical devices |
| `swiftlint` | Swift lint with nvim-lint |

Xcode gives `sourcekit-lsp` (Swift LSP) and `lldb` (debugger).

The config also calls `swiftformat` (Swift format on save) and `xcodegen` (`<leader>xg`).
Install them only if you need them: `brew install swiftformat xcodegen`.

Restart Neovim and run:

```vim
:checkhealth xcodebuild
```

Run `:XcodebuildSetup` once in each project.

New Swift files get a template from `~/.config/nvim/lua/templates/`. See `lua/templates/command.lua`.

## Fixed paths

The config expects these paths. If a path is different on your Mac, change it in the file.

| Path | File |
| :--- | :--- |
| `~/.config/android.nvim` | `lua/custom/plugins/android.lua` |
| `~/StudioProjects/polarsteps-review-assistant/nvim` | `lua/custom/plugins/pr-review.lua` |
| `/opt/homebrew/opt/kotlin-lsp/libexec` | `lua/custom/plugins/kotlin.lua` |
| `/Applications/Android Studio.app/Contents/jbr/Contents/Home` | `lua/custom/plugins/kotlin.lua` |
