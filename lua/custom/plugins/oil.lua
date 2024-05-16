vim.keymap.set('n', '<leader>ef', ':Oil<CR>', { desc = 'Launch oil' })

return {
  'stevearc/oil.nvim',
  opts = {
    default_file_explorer = true,
    delete_to_trash = false,
  },
  -- Optional dependencies
  dependencies = { 'nvim-tree/nvim-web-devicons' },
}
