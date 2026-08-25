local M = {}

local state = {
  buf = nil,
  win = nil,
}

local function get_shell_cmd()
  if vim.fn.has 'win32' == 1 then
    -- Git Bash (meest stabiel) -- check the common install locations rather than hardcoding one,
    -- since a non-default/portable install (scoop, per-user AppData, 32-bit) won't be there.
    local candidates = {
      'C:/Program Files/Git/bin/bash.exe',
      'C:/Program Files (x86)/Git/bin/bash.exe',
      vim.fn.expand '~/scoop/apps/git/current/bin/bash.exe',
      vim.fn.expand '~/AppData/Local/Programs/Git/bin/bash.exe',
    }
    for _, path in ipairs(candidates) do
      if vim.fn.filereadable(path) == 1 then
        return { path, '--login', '-i' }
      end
    end
    vim.notify('Git Bash not found in common install locations, falling back to ' .. vim.o.shell, vim.log.levels.WARN)
    -- Zonder de bash-vlaggen: de fallback is hier cmd.exe of PowerShell, en die
    -- weigeren te starten op `--login`/`-i`.
    return { vim.o.shell }
  end
  return { vim.o.shell, '--login', '-i' }
end

local function create_window()
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })

  vim.cmd 'startinsert'
end

function M.toggle()
  -- window bestaat → sluit alleen window
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
    return
  end

  -- buffer bestaat niet → maak terminal buffer
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].bufhidden = 'hide' -- nvim_buf_set_option() is deprecated; index vim.bo instead

    create_window()
    -- termopen() is deprecated (zie `:help deprecated`); jobstart met `term = true`
    -- is de vervanger.
    vim.fn.jobstart(get_shell_cmd(), { term = true })
    return
  end

  -- buffer bestaat → heropen window
  create_window()
end

return M
