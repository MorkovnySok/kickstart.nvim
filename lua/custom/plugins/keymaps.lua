local map = vim.keymap.set
local utils = require 'utils'

map('n', '<leader>ll', 'a<Esc>:%!dos2unix<CR>gi<Esc>', { desc = 'Convert CRLF to LF' })

map('n', '<leader>fd', function()
  local path = vim.fn.expand '%:p:h:t'
  vim.fn.setreg('+', path)
  print('Copied to clipboard: ' .. path)
end, { desc = 'Copy [F]ile [D]irectory to clipboard' })
-- map('n', '<C-t>', ':e %:p:r.ts<CR>', { desc = 'Go to typescript' })
-- map('n', '<C-g>', ':e %:p:r.html<CR>', { desc = 'Go to html' })
-- map('n', '<C-b>', ':e %:p:r.css<CR>', { desc = 'Go to css' })

map('n', '+', '<C-a>')
map('n', '-', '<C-x>')
map('v', '+', '<C-a>gv', { desc = 'Increment numbers' })
map('v', '-', '<C-x>gv', { desc = 'Decrement numbers' })
map('n', '<C-d>', '<C-d>zz')
map('n', '<C-u>', '<C-u>zz')
map('n', 'n', 'nzzzv')
map('n', 'N', 'Nzzzv')
map('n', '<leader>ih', '<C-w>|<C-w>_', { desc = 'Maximize buffer' })

map('x', '<leader>p', '"_dP')
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
map('n', '<leader>tc', function()
  vim.cmd 'cd %:p:h'
  vim.cmd 'split'
  vim.cmd 'terminal pwsh'
  vim.cmd 'startinsert'
end, { desc = 'Start powershell and cd to current directory' })

-- git
map('n', '<leader>ga', ':Git blame<CR>', { silent = true, desc = 'Git blame' })

--trees
map('n', '<leader>eo', ':Oil --float<CR>', { desc = 'Launch oil' })
map('n', '<leader>ew', ':NvimTreeToggle<CR>', { desc = 'Open tree' })
map('n', '<leader>ef', ':NvimTreeFindFile<CR>', { desc = 'Find file in a tree' })
map('n', '<leader>ex', ':silent !explorer "%:p:h"<CR>', { desc = 'Find file in a tree', silent = true })

-- open in code
map('n', '<leader>fc', ':silent !code %<CR>', { desc = '[F]ile Open in Vs[C]ode', silent = true })
map('n', '<leader>fy', ':let @+ = expand("%")<CR>', { desc = 'Yank File name to clip', silent = true })
map('n', '<leader>fo', ':silent !wslview %<CR>', { desc = '[F]ile [O]pen with wslview', silent = true })
map('n', '<leader>fo', function()
  utils.do_on_file(function(path)
    vim.system { 'wslview', path }
  end)
end, { desc = '[F]ile [O]pen with wslview', silent = true })
map('n', '<leader>fe', ':silent !wslview %:p:h<CR>', { desc = '[F]ile Open with [E]xplorer', silent = true })

-- Enable Ctrl+hjkl movements in Insert mode
map('i', '<C-h>', '<Left>', { desc = 'Move left in insert mode' })
map('i', '<C-j>', '<Down>', { desc = 'Move down in insert mode' })
map('i', '<C-k>', '<Up>', { desc = 'Move up in insert mode' })
map('i', '<C-l>', '<Right>', { desc = 'Move right in insert mode' })

map('n', '<leader>lR', ':LspRestart<CR>', { desc = 'Restart LSP', silent = true })

-- diagnostics
map('n', '[d', function()
  vim.diagnostic.goto_prev()
end, { desc = 'Jump to previous diagnostic' })
map('n', ']d', function()
  vim.diagnostic.goto_next()
end, { desc = 'Jump to next diagnostic' })

-- Database
map('n', '<leader>dw', ':DBUIToggle<CR>', { desc = 'Toggle DBUI', silent = true })

return {}
