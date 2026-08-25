-- Personal autocommands go here.
--
-- (Previously held the <leader>r / <leader>t run-and-test-file keymaps -- removed by request.)

-- Neovim 0.12 detecteert *.component.html nog gewoon als `html`, ook met Angular-syntax
-- erin. Met `htmlangular` krijg je de treesitter `angular`-parser (in plaats van de kale
-- html-parser) en houd je de generieke html-LSP weg bij Angular-templates -- angularls
-- staat zelf wel op deze filetype ingeschreven.
vim.filetype.add {
  pattern = {
    ['.*%.component%.html'] = 'htmlangular',
  },
}
