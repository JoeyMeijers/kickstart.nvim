return {
  'rose-pine/neovim',
  name = 'rose-pine',
  config = function()
    vim.cmd 'colorscheme rose-pine'
    require('rose-pine').setup {
      disable_background = true,
    }
  end,
}
