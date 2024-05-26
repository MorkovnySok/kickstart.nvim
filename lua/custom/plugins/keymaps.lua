vim.keymap.set('n', '<C-t>', ':e %:p:r.ts<CR>', { desc = 'Go to typescript' })
vim.keymap.set('n', '<C-g>', ':e %:p:r.html<CR>', { desc = 'Go to html' })
vim.keymap.set('n', '<C-b>', ':e %:p:r.css<CR>', { desc = 'Go to css' })

vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

vim.keymap.set('x', '<leader>p', [["_dP]])
vim.keymap.set('i', '<C-c>', '<Esc>')

vim.keymap.set('n', '<C-k>', '<cmd>cnext<CR>zz')
vim.keymap.set('n', '<C-j>', '<cmd>cprev<CR>zz')

vim.keymap.set('n', '<C-Left>', ':vertical resize -10<CR>')
vim.keymap.set('n', '<C-Right>', ':vertical resize +10<CR>')
vim.keymap.set('n', '<C-Up>', ':resize -5<CR>')
vim.keymap.set('n', '<C-Down>', ':resize +5<CR>')

return {}
