local M = {}

local state = {
  buf = nil,
  win = nil,
}

local function get_shell()
  if vim.fn.has 'win32' == 1 then
    -- Git Bash (meest stabiel)
    return 'C:/Program Files/Git/bin/bash.exe'
  end
  return vim.o.shell
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
    vim.api.nvim_buf_set_option(state.buf, 'bufhidden', 'hide')

    create_window()
    vim.fn.termopen { get_shell(), '--login', '-i' }
    return
  end

  -- buffer bestaat → heropen window
  create_window()
end

return M
