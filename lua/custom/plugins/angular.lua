vim.filetype.add {
  pattern = {
    ['.*%.component%.html'] = 'htmlangular',
  },
}

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'htmlangular',
  callback = function()
    vim.treesitter.language.register('angular', 'htmlangular')
  end,
})

return {}
