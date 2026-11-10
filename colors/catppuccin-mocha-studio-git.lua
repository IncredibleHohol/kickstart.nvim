-- catppuccin-mocha, with the git diff colors of Android Studio 2026.2 (the "Dark" editor scheme).
-- Studio keys: DIFF_INSERTED, DIFF_MODIFIED, DIFF_DELETED, DIFF_SEPARATORS_BACKGROUND, FOLDED_TEXT_ATTRIBUTES.
require('catppuccin').load 'mocha'
vim.g.colors_name = 'catppuccin-mocha-studio-git'

local hl = vim.api.nvim_set_hl

-- Set the background only. Diffview copies DiffDelete to the removed lines of the left pane,
-- so a foreground here would repaint the syntax colors of those lines.
hl(0, 'DiffAdd', { bg = '#294436' }) -- DIFF_INSERTED
hl(0, 'DiffChange', { bg = '#30445c' }) -- DIFF_MODIFIED, blended 70% with the editor background
hl(0, 'DiffText', { bg = '#43698d' }) -- DIFF_MODIFIED error stripe: the changed words of a changed line
hl(0, 'DiffDelete', { bg = '#553f41' }) -- DIFF_DELETED (#484a4a), with some red added

-- The bar of the collapsed unchanged lines.
hl(0, 'Folded', { fg = '#868991', bg = '#2b2d30' }) -- FOLDED_TEXT_ATTRIBUTES fg, DIFF_SEPARATORS_BACKGROUND bg
