local M = {}

local state = {
  buf = nil,
  win = nil,
}

-- Zonder dit beland je bij het terugwisselen naar het terminalvenster (bv. met
-- <C-l>) in Terminal-Normal-mode i.p.v. terminal-mode: het venster wisselt wel,
-- maar je kunt niet typen tot je zelf op i drukt -- voelt aan als "doet niks".
vim.api.nvim_create_autocmd('WinEnter', {
  desc = 'Terminal-mode hervatten bij het betreden van een terminalvenster',
  callback = function()
    if vim.bo.buftype == 'terminal' then
      vim.cmd 'startinsert'
    end
  end,
})

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
  -- Een echte vsplit rechts i.p.v. een float: gewoon navigeerbaar met <C-w>/
  -- <C-h>/<C-l> en resizebaar zoals elk ander venster, geen aparte overlay-modus.
  --
  -- botright i.p.v. nvim_open_win met split='right': die laatste splitst relatief
  -- aan wat toevallig het actieve venster is (bv. naast Neo-tree als dat net
  -- focus had), niet per se de rechterrand van het hele tabblad. botright dwingt
  -- altijd de buitenste rechterkolom af, ongeacht waar je vandaan komt, zodat
  -- <C-l> vanuit je editvenster hem altijd bereikt.
  vim.cmd 'botright vsplit'
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, state.buf)
  vim.api.nvim_win_set_width(state.win, math.floor(vim.o.columns * 0.4))

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
