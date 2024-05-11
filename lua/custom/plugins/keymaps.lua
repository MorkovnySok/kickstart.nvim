vim.keymap.set('n', '<C-t>', ':e %:p:r.ts<CR>', { desc = 'Go to typescript' })
vim.keymap.set('n', '<C-g>', ':e %:p:r.html<CR>', { desc = 'Go to html' })
vim.keymap.set('n', '<C-b>', ':e %:p:r.css<CR>', { desc = 'Go to css' })

return {}
