return {
  'ThePrimeagen/harpoon',
  -- 2026-08: pinned to the harpoon2 rewrite -- the default branch is the old v1 API
  -- (harpoon.mark / harpoon.ui), which still works but isn't where development happens anymore.
  -- API reference: https://github.com/ThePrimeagen/harpoon/blob/harpoon2/README.md
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require 'harpoon'
    -- NOTE: harpoon2's setup() takes a different options shape than v1 (settings/key(), not
    -- menu.width) -- dropped the old menu-width customization rather than guess at a wrong key.
    harpoon:setup()

    vim.keymap.set('n', '<leader>a', function()
      harpoon:list():add()
    end, { desc = 'Harpoon: Add file' })
    vim.keymap.set('n', '<C-e>', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = 'Harpoon: Toggle menu' })

    for i = 1, 4 do
      vim.keymap.set('n', '<leader>' .. i, function()
        harpoon:list():select(i)
      end, { desc = 'Harpoon: Navigate to file ' .. i })
    end
  end,
}
