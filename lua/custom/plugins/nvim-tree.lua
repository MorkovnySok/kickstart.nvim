vim.keymap.set('n', '<leader>ew', ':NvimTreeToggle<CR>', { desc = 'Open tree' })
vim.keymap.set('n', '<leader>ef', ':NvimTreeFindFile<CR>', { desc = 'Find file in a tree' })

return {
  'nvim-tree/nvim-tree.lua',
  version = '*',
  lazy = false,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require('nvim-tree').setup {}
  end,
}
