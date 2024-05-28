local map = vim.keymap.set

map('n', '<C-t>', ':e %:p:r.ts<CR>', { desc = 'Go to typescript' })
map('n', '<C-g>', ':e %:p:r.html<CR>', { desc = 'Go to html' })
map('n', '<C-b>', ':e %:p:r.css<CR>', { desc = 'Go to css' })

map('n', '<C-d>', '<C-d>zz')
map('n', '<C-u>', '<C-u>zz')
map('n', 'n', 'nzzzv')
map('n', 'N', 'Nzzzv')

map('x', '<leader>p', [["_dP]])
map('i', '<C-c>', '<Esc>')

map('n', '<C-Left>', "<cmd>lua require'utils'.resize(true, -5)<CR>")
map('n', '<C-Right>', "<cmd>lua require'utils'.resize(true, 5)<CR>")
map('n', '<C-Up>', "<cmd>lua require'./utils'.resize(false, -5)<CR>")
map('n', '<C-Down>', "<cmd>lua require'./utils'.resize(false,  5)<CR>")

-- terminal stuff
map('t', '<Esc>', '<C-\\><C-n>', { desc = 'Normal mode in terminal', noremap = true })
map('n', '<leader>tr', ':te pwsh<CR>', { desc = 'Start powershell' })
map('n', '<leader>ts', '<C-w>s:te pwsh<CR>', { desc = 'Start powershell in [s]plit' })
map('n', '<leader>tv', '<C-w>v:te pwsh<CR>', { desc = 'Start powershell in [v]ertical split' })

return {}
