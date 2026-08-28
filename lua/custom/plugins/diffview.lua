-- Vult aan waar gitsigns ophoudt. Gitsigns werkt per hunk in de buffer waar je in zit;
-- diffview geeft het overzicht van een hele branch (bestandenpaneel links, diff rechts)
-- en -- belangrijker -- een 3-weg view om merge-conflicten in op te lossen, wat deze
-- config verder helemaal niet heeft.
--
--   <leader>gv                  openen/sluiten (huidige working tree)
--   <leader>gV                  alles wat je branch toevoegt sinds main/master
--   <leader>gh                  historie van dit bestand, doorbladerbaar
--   :DiffviewOpen               tijdens een merge/rebase: de conflicten, 3-weg

-- Bepaalt de default branch om <leader>gV tegen te diffen. Eerst origin/HEAD
-- (de normale situatie); dat remote-ref bestaat niet in een config die via
-- import-offline.ps1 is binnengehaald (origin wordt daar bewust verwijderd),
-- dus dan terugvallen op een lokale main- of master-branch, welke er ook is.
local function default_branch()
  local ref = vim.fn.systemlist('git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null')[1]
  if vim.v.shell_error == 0 and ref and ref ~= '' then
    return ref
  end
  for _, name in ipairs { 'main', 'master' } do
    vim.fn.system('git rev-parse --verify ' .. name .. ' 2>/dev/null')
    if vim.v.shell_error == 0 then
      return name
    end
  end
  return 'HEAD'
end

return {
  'sindrets/diffview.nvim',
  -- Geen reden om dit bij elke start op te tuigen: laden zodra je het aanroept.
  cmd = {
    'DiffviewOpen',
    'DiffviewClose',
    'DiffviewFileHistory',
    'DiffviewFocusFiles',
    'DiffviewToggleFiles',
    'DiffviewRefresh',
  },
  keys = {
    {
      '<leader>gv',
      function()
        -- Er is geen ingebouwd toggle-commando; open of sluit op basis van wat er staat.
        if require('diffview.lib').get_current_view() then
          vim.cmd 'DiffviewClose'
        else
          vim.cmd 'DiffviewOpen'
        end
      end,
      desc = 'Git: diff[v]iew openen/sluiten',
    },
    {
      '<leader>gV',
      function()
        vim.cmd('DiffviewOpen ' .. default_branch() .. '...HEAD')
      end,
      desc = 'Git: diff[V]iew tegen main/master sinds branch-punt',
    },
    {
      '<leader>gh',
      function()
        vim.cmd 'DiffviewFileHistory %'
      end,
      desc = 'Git: [h]istorie van dit bestand',
    },
  },
  opts = function()
    local opts = {
      -- Rijkere kleuring van de diff-regels dan vims eigen diff-mode geeft.
      enhanced_diff_hl = true,
      -- Staat standaard aan en vereist nvim-web-devicons; deze config heeft dat niet
      -- (kickstart is overgestapt op mini.icons).
      use_icons = vim.g.have_nerd_font,
      -- Standaard 35. Met listing_style = 'tree' worden geneste paden ingesprongen
      -- getoond, en in een repo met diepe mappen valt dat net te krap uit.
      file_panel = {
        win_config = { width = 45 },
      },
    }
    if not vim.g.have_nerd_font then
      -- De standaardwaarden hiervan komen uit een Nerd Font en worden anders blokjes.
      opts.signs = { fold_closed = '▸', fold_open = '▾', done = '✓' }
      opts.icons = { folder_closed = '▸', folder_open = '▾' }
    end
    return opts
  end,
}
