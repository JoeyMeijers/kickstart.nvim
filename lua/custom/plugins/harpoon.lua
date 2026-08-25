-- Lazy-load op de keymaps zelf, net als undotree. Een spec met alleen een `config`-
-- functie en geen `keys`/`event`-trigger laadt lazy.nvim onvoorwaardelijk bij elke
-- start -- harpoon kostte zo ~11 ms van een startup van ~175 ms.
local keys = {
  {
    '<leader>a',
    function()
      require('harpoon'):list():add()
    end,
    desc = 'Harpoon: Add file',
  },
  {
    '<C-e>',
    function()
      local harpoon = require 'harpoon'
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end,
    desc = 'Harpoon: Toggle menu',
  },
}

for i = 1, 4 do
  table.insert(keys, {
    '<leader>' .. i,
    function()
      require('harpoon'):list():select(i)
    end,
    desc = 'Harpoon: Navigate to file ' .. i,
  })
end

return {
  'ThePrimeagen/harpoon',
  -- 2026-08: pinned to the harpoon2 rewrite -- the default branch is the old v1 API
  -- (harpoon.mark / harpoon.ui), which still works but isn't where development happens anymore.
  -- API reference: https://github.com/ThePrimeagen/harpoon/blob/harpoon2/README.md
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = keys,
  config = function()
    -- NOTE: harpoon2's setup() takes a different options shape than v1 (settings/key(), not
    -- menu.width) -- dropped the old menu-width customization rather than guess at a wrong key.
    require('harpoon'):setup()
  end,
}
