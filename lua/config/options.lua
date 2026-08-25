vim.opt.colorcolumn = '80'
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.guicursor = ''

vim.opt.swapfile = false
vim.opt.backup = false

-- Remote-plugin providers: deze config gebruikt geen enkele plugin die in Perl,
-- Ruby, Python of Node geschreven is, dus laat Neovim er niet naar zoeken. Dit
-- scheelt alleen `:checkhealth`-ruis -- het raakt LSP-servers niet, die draaien
-- als losse processen en niet via een provider.
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0

-- Sinds Neovim 0.11 staat `virtual_text` standaard uit. Zonder deze config zie je
-- alleen een teken in de signcolumn plus een onderstreping, en moet je met <C-W>d
-- op de fout gaan staan om te lezen wat er mis is.
vim.diagnostic.config {
  severity_sort = true,
  underline = true,
  virtual_text = {
    spacing = 2,
    source = 'if_many', -- toon de bron alleen als er meerdere servers aan deze buffer hangen
  },
  float = {
    border = 'rounded',
    source = 'if_many',
  },
}

local undodir = vim.fn.stdpath 'state' .. '/undo'
vim.fn.mkdir(undodir, 'p')
vim.opt.undodir = undodir
