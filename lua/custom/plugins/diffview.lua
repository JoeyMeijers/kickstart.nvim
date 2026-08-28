-- Vult aan waar gitsigns ophoudt. Gitsigns werkt per hunk in de buffer waar je in zit;
-- diffview geeft het overzicht van een hele branch (bestandenpaneel links, diff rechts)
-- en -- belangrijker -- een 3-weg view om merge-conflicten in op te lossen, wat deze
-- config verder helemaal niet heeft.
--
--   :DiffviewOpen main...HEAD   alles wat jouw branch toevoegt sinds de merge-base
--   :DiffviewFileHistory %      de historie van dit bestand, doorbladerbaar
--   :DiffviewOpen               tijdens een merge/rebase: de conflicten, 3-weg
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
