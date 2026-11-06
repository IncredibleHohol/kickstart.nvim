-- Marks the lines that the commits of this branch change, as Android Studio does for a pull request.
-- The base is the merge-base with the PR base branch (`gh pr view`), or with origin/HEAD when there is no PR.
-- gitsigns keeps the uncommitted changes: its signs have a higher priority, so they win on the same line.
return {
  'pr-signs',
  virtual = true,
  config = function()
    local ns = vim.api.nvim_create_namespace 'pr_signs'
    -- git root -> { head = HEAD sha, base = merge-base sha }
    local repos = {}
    -- buffer -> { base = merge-base sha, text = file text at the merge-base }
    local files = {}

    local function set_hl()
      vim.api.nvim_set_hl(0, 'PrSignsChange', { fg = '#8b6cae' })
    end

    --- Calls back with stdout, or with nil when git fails.
    local function git(root, args, cb)
      vim.system(vim.list_extend({ 'git', '-C', root }, args), { text = true }, function(r)
        vim.schedule(function()
          cb(r.code == 0 and r.stdout or nil)
        end)
      end)
    end

    local function base_branch(root, cb)
      vim.system({ 'gh', 'pr', 'view', '--json', 'baseRefName', '-q', '.baseRefName' }, { cwd = root, text = true }, function(r)
        vim.schedule(function()
          if r.code == 0 then
            return cb('origin/' .. vim.trim(r.stdout))
          end
          git(root, { 'rev-parse', '--abbrev-ref', 'origin/HEAD' }, function(out)
            cb(out and vim.trim(out))
          end)
        end)
      end)
    end

    --- Calls back with the merge-base sha, or with nil when there is no base. Finds it again when HEAD changes.
    local function resolve(root, cb)
      git(root, { 'rev-parse', 'HEAD' }, function(head)
        if not head then
          return cb(nil)
        end
        local repo = repos[root]
        if repo and repo.head == head then
          return cb(repo.base)
        end
        base_branch(root, function(branch)
          if not branch then
            return cb(nil)
          end
          git(root, { 'merge-base', 'HEAD', branch }, function(base)
            base = base and vim.trim(base)
            repos[root] = { head = head, base = base }
            cb(base)
          end)
        end)
      end)
    end

    local function mark(buf, row, text)
      vim.api.nvim_buf_set_extmark(buf, ns, row, 0, { sign_text = text, sign_hl_group = 'PrSignsChange', priority = 5 })
    end

    local function draw(buf)
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      local text = files[buf] and files[buf].text
      if not text then
        return
      end
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local current = table.concat(lines, '\n') .. (vim.bo[buf].eol and '\n' or '')
      for _, hunk in ipairs(vim.text.diff(text, current, { result_type = 'indices' })) do
        local start, count = hunk[3], hunk[4]
        if count > 0 then
          for row = start - 1, start + count - 2 do
            mark(buf, row, '┃')
          end
        elseif start > 0 then
          mark(buf, start - 1, '_')
        else
          mark(buf, 0, '‾')
        end
      end
    end

    local function load(buf, root, base, cb)
      local rel = vim.api.nvim_buf_get_name(buf):sub(#root + 2)
      git(root, { 'show', base .. ':' .. rel }, function(text)
        if text then
          return cb(text)
        end
        -- A file that this branch adds has no base version. Mark it only when it is committed, not when it is untracked or ignored.
        git(root, { 'cat-file', '-e', 'HEAD:' .. rel }, function(out)
          cb(out and '' or nil)
        end)
      end)
    end

    local function update(buf)
      if vim.bo[buf].buftype ~= '' then
        return
      end
      local path = vim.api.nvim_buf_get_name(buf)
      local root = path ~= '' and vim.fs.root(path, '.git')
      if not root then
        return
      end
      resolve(root, function(base)
        if not base then
          files[buf] = nil
          return draw(buf)
        end
        if files[buf] and files[buf].base == base then
          return draw(buf)
        end
        load(buf, root, base, function(text)
          if vim.api.nvim_buf_is_valid(buf) then
            files[buf] = { base = base, text = text }
            draw(buf)
          end
        end)
      end)
    end

    set_hl()
    local group = vim.api.nvim_create_augroup('PrSigns', { clear = true })
    vim.api.nvim_create_autocmd('ColorScheme', { group = group, callback = set_hl })
    vim.api.nvim_create_autocmd('BufEnter', {
      group = group,
      callback = function(ev)
        update(ev.buf)
      end,
    })
    -- A branch can change outside of nvim, for example in a terminal.
    vim.api.nvim_create_autocmd('FocusGained', {
      group = group,
      callback = function()
        update(vim.api.nvim_get_current_buf())
      end,
    })
    vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
      group = group,
      callback = function(ev)
        local tick = vim.b[ev.buf].changedtick
        vim.defer_fn(function()
          if vim.api.nvim_buf_is_valid(ev.buf) and vim.b[ev.buf].changedtick == tick then
            draw(ev.buf)
          end
        end, 200)
      end,
    })
    vim.api.nvim_create_autocmd('BufWipeout', {
      group = group,
      callback = function(ev)
        files[ev.buf] = nil
      end,
    })
  end,
}
