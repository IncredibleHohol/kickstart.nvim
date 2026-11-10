return {
  -- lazy names a plugin after its folder, and catppuccin/nvim is "nvim" already
  name = 'pr-review',
  dir = '~/StudioProjects/polarsteps-review-assistant/nvim',
  dependencies = { 'sindrets/diffview.nvim', 'nvim-telescope/telescope.nvim' },
  cmd = 'PrReview',
  keys = { { '<leader>rr', desc = 'Review: the pull requests' } },
  config = function()
    -- the same as Settings > Tools > PR Review Assistant in Android Studio
    require('pr-review').setup {
      cli = 'claude',
      model = 'opus',
      effort = 'xhigh',
      grammar_model = 'haiku',
      moves = true,
      reviewers = {
        'claude:opus#xhigh',
        'omp:openai-codex/gpt-6.1-sol#xhigh',
        'omp:openai-codex/gpt-6.1-sol#high',
        'omp:openai-codex/gpt-6.1-sol#medium',
        'omp:openai-codex/gpt-6.1-sol#low',
        'omp:openai-codex/gpt-6-astra#xhigh',
        'omp:openai-codex/gpt-6-astra#high',
        'omp:openai-codex/gpt-6-astra#medium',
        'omp:openai-codex/gpt-6-astra#low',
      },
    }
  end,
}
