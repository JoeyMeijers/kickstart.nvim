local map = vim.keymap.set

map('n', '<leader>pv', vim.cmd.Ex, { desc = 'Open file explorer' })
map('v', 'J', ":m '>+1<CR>gv=gv")
map('v', 'K', ":m '<-2<CR>gv=gv")
map('n', 'J', 'mzJ`z')
map('n', '<C-d>', '<C-d>zz')
map('n', '<C-u>', '<C-u>zz')
map('n', 'n', 'nzzzv')
map('n', 'N', 'Nzzzv')

map('n', '<leader>w', '<cmd>write<CR>', { desc = 'Write buffer' })
map('n', '<leader>e', '<cmd>Neotree toggle<CR>', { desc = 'Toggle file explorer' })

local function telescope_builtin(name, opts)
  return function()
    require('telescope.builtin')[name](opts)
  end
end

map('n', '<leader>gc', telescope_builtin 'git_commits', { desc = 'Git commits' })
map('n', '<leader>gC', telescope_builtin 'git_bcommits', { desc = 'Git buffer commits' })
map('n', '<leader>gb', telescope_builtin 'git_branches', { desc = 'Git branches' })
map('n', '<leader>gl', telescope_builtin 'git_commits', { desc = 'Git log' })
map('n', '<leader>gd', telescope_builtin('git_bcommits', { show_diff = true }), { desc = 'Git file diff' })
map('n', '<leader>gS', telescope_builtin 'git_stash', { desc = 'Git stash list' })
map('n', '<leader>gs', '<cmd>Telescope git_status<CR>', { desc = 'Git status' })
map('n', '<leader>gbn', function()
  require('gitsigns').blame_line { full = true }
end, { desc = 'Git blame line' })

map({ 'n', 't' }, '<leader>tt', function()
  require('custom.floating_terminal').toggle()
end, { desc = 'Toggle floating terminal' })
