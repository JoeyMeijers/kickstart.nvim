return {
  'mbbill/undotree',
  -- `keys` both defines the mapping and lazy-loads the plugin on first press, instead of loading
  -- unconditionally on every startup for something used occasionally.
  keys = {
    { '<leader>u', '<cmd>UndotreeToggle<CR>', desc = 'Toggle Undotree' },
  },
  config = function()
    -- Configuratie voor undotree
    vim.g.undotree_WindowLayout = 2 -- Zet de layout
    vim.g.undotree_SplitWidth = 30 -- Stel de breedte van het undotree-venster in
    vim.g.undotree_SetFocusWhenToggle = 1 -- Focus op undotree bij openen
  end,
}
