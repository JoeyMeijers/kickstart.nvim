local run_commands = {
  python = '<cmd>write<CR><cmd>!python3 %<CR>',
  r = '<cmd>write<CR><cmd>!Rscript %<CR>',
  cs = '<cmd>write<CR><cmd>!dotnet run<CR>',
  c = '<cmd>write<CR><cmd>!gcc -Wall -Wextra -g % -o %:r && ./%:r<CR>',
  cpp = '<cmd>write<CR><cmd>!g++ -Wall -Wextra -g % -o %:r && ./%:r<CR>',
  go = '<cmd>write<CR><cmd>!go run %<CR>',
}

local test_commands = {
  python = '<cmd>write<CR><cmd>!pytest<CR>',
  r = '<cmd>write<CR><cmd>!Rscript -e "devtools::test()"<CR>',
  cs = '<cmd>write<CR><cmd>!dotnet test<CR>',
}

vim.api.nvim_create_autocmd('FileType', {
  pattern = vim.tbl_keys(run_commands),
  callback = function(event)
    local filetype = vim.bo[event.buf].filetype
    vim.keymap.set('n', '<leader>r', run_commands[filetype], {
      buffer = event.buf,
      silent = true,
      desc = 'Run current file or project',
    })

    if test_commands[filetype] then
      vim.keymap.set('n', '<leader>t', test_commands[filetype], {
        buffer = event.buf,
        silent = true,
        desc = 'Run tests',
      })
    end
  end,
})
