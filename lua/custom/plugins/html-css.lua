return {
  'Jezda1337/nvim-html-css',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
  },
  config = function(_, opts)
    require('html-css').setup(opts)
  end,
  opts = {
    enable_on = {
      'astro',
      'html',
      'typescriptreact',
      'javascriptreact',
      'svelte',
      'vue',
    },
    documentation = {
      auto_show = true,
    },
    style_sheets = {
      './src/styles/global.css',
    },
  },
}
