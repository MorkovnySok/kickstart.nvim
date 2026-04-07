return {
  'windwp/nvim-ts-autotag',
  main = 'nvim-ts-autotag',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {
    opts = {
      enable_close = true,
      enable_rename = true,
      enable_close_on_slash = false,
    },
    per_filetype = {
      htmlangular = {
        enable_close = true,
        enable_rename = true,
      },
    },
    aliases = {
      angular = 'html',
    },
  },
}
