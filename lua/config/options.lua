vim.opt.colorcolumn = '80'
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.guicursor = ''

vim.opt.swapfile = false
vim.opt.backup = false

local undodir = vim.fn.expand '~/.vim/undodir'
vim.fn.mkdir(undodir, 'p')
vim.opt.undodir = undodir
