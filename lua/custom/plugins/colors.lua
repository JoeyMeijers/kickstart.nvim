return {
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    config = function()
      -- setup() moet vóór het laden van het colorscheme: rose-pine leest zijn opties
      -- op het moment dat `colorscheme` draait, niet daarna.
      require('rose-pine').setup {
        disable_background = true,
      }
      vim.cmd 'colorscheme rose-pine'
    end,
  },
}
