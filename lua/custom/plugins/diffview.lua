local function git(cwd, args)
  local result = vim.system(vim.list_extend({ 'git' }, args), { cwd = cwd }):wait()
  assert(result.code == 0, result.stderr)
  return result.stdout
end

-- Returns a path to the content of one side of the diff. Each content gets its
-- own path, because snacks.image caches a converted image by its source path.
local function side_path(file)
  local RevType = require('diffview.vcs.rev').RevType
  local cwd = file.adapter.ctx.toplevel
  local is_local = file.rev.type == RevType.LOCAL
  local hash = vim.trim(git(cwd, is_local and { 'hash-object', '--', file.path } or { 'rev-parse', file.rev:object_name() .. ':' .. file.path }))
  local label = is_local and 'working' or file.rev.type == RevType.STAGE and 'index' or file.rev:object_name(10)
  local dir = vim.fn.stdpath 'cache' .. '/diffview-images/' .. hash
  local path = dir .. '/' .. label .. '_' .. file.basename
  if not vim.uv.fs_stat(path) then
    vim.fn.mkdir(dir, 'p')
    if is_local then
      assert(vim.uv.fs_copyfile(file.absolute_path, path))
    else
      local out = assert(io.open(path, 'wb'))
      out:write(git(cwd, { 'cat-file', 'blob', hash }))
      out:close()
    end
  end
  return path
end

-- Diffview shows an empty buffer for binary files. In a terminal with the kitty
-- graphics protocol (Ghostty), show image files with snacks.image instead.
local function show_image(_, winid)
  local view = require('diffview.lib').get_current_view()
  local win = view and vim.iter(view.cur_layout.windows):find(function(w)
    return w.id == winid
  end)
  local file = win and win.file
  if not (file and file.binary and not file.nulled and Snacks.image.supports(file.path)) then
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.api.nvim_win_set_buf(winid, buf)
  -- in diff mode, the equal lines of the two image buffers fold away
  vim.wo[winid].diff = false
  Snacks.image.buf.attach(buf, { src = side_path(file) })
end

return {
  'sindrets/diffview.nvim',
  keys = {
    {
      '<leader>gd',
      function()
        if require('diffview.lib').get_current_view() then
          vim.cmd 'DiffviewClose'
        else
          vim.cmd 'DiffviewOpen'
        end
      end,
      desc = '[D]iffview: open or close',
    },
    { '<leader>gh', '<Cmd>DiffviewFileHistory %<CR>', desc = 'File [h]istory' },
  },
  opts = {
    -- the file list on the right, as the review plugin and nvim-tree show it
    file_panel = {
      win_config = { position = 'right', width = 50 },
    },
    hooks = { diff_buf_win_enter = show_image },
  },
}
