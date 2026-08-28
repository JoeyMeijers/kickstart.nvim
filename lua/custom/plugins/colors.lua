return {
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    config = function()
      -- setup() moet vóór het laden van het colorscheme: rose-pine leest zijn opties
      -- op het moment dat `colorscheme` draait, niet daarna.
      require('rose-pine').setup {
        -- Dekt zowel de gewone buffer als floats (Telescope, which-key, hover, ...) in
        -- één keer. disable_background/disable_float_background zijn deprecated en
        -- dekten alleen de buffer, waardoor floats een effen achtergrond behielden.
        styles = { transparency = true },
      }
      vim.cmd 'colorscheme rose-pine'
    end,
  },
}
