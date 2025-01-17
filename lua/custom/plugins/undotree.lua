return {
  'mbbill/undotree',
  config = function()
    -- Configuratie voor undotree
    vim.g.undotree_WindowLayout = 2 -- Zet de layout
    vim.g.undotree_SplitWidth = 30 -- Stel de breedte van het undotree-venster in
    vim.g.undotree_SetFocusWhenToggle = 1 -- Focus op undotree bij openen

    -- Keymap voor undotree
    vim.keymap.set('n', '<leader>u', ':UndotreeToggle<CR>', { noremap = true, silent = true, desc = 'Toggle Undotree' })
  end,
}
