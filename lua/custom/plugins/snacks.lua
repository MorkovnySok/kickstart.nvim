return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  init = function()
    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      callback = function()
        Snacks.toggle.option('spell', { name = 'Spelling' }):map '<leader>us'
        Snacks.toggle.option('wrap', { name = 'Wrap' }):map '<leader>uw'
        Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):map '<leader>uL'
        Snacks.toggle.diagnostics():map '<leader>ud'
        Snacks.toggle.line_number():map '<leader>ul'
        Snacks.toggle.option('conceallevel', {
          off = 0,
          on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2,
          name = 'Conceal',
        }):map '<leader>uc'
        Snacks.toggle.treesitter():map '<leader>uT'
        Snacks.toggle.option('background', {
          off = 'light',
          on = 'dark',
          name = 'Dark Background',
        }):map '<leader>ub'
        Snacks.toggle.inlay_hints():map '<leader>uh'
        Snacks.toggle.indent():map '<leader>ug'
        Snacks.toggle.dim():map '<leader>uD'
        Snacks.toggle.words():map '<leader>ur'
        Snacks.toggle.zen():map '<leader>uz'
        Snacks.toggle.zoom():map '<leader>uZ'
      end,
    })
  end,
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    dim = { enabled = true },
    explorer = { enabled = false },
    gitbrowse = { enabled = true },
    image = { enabled = false },
    indent = { enabled = true },
    input = { enabled = true },
    lazygit = { enabled = false },
    notifier = { enabled = true },
    picker = { enabled = false },
    quickfile = { enabled = true },
    rename = { enabled = true },
    scope = { enabled = true },
    scratch = { enabled = true },
    scroll = { enabled = false },
    statuscolumn = { enabled = false },
    terminal = { enabled = false },
    toggle = { enabled = true },
    words = { enabled = true },
    zen = { enabled = true },
  },
  keys = {
    {
      '<leader>.',
      function()
        Snacks.scratch()
      end,
      desc = 'Toggle scratch buffer',
    },
    {
      '<leader>S',
      function()
        Snacks.scratch.select()
      end,
      desc = 'Select scratch buffer',
    },
    {
      '<leader>nh',
      function()
        Snacks.notifier.show_history()
      end,
      desc = '[N]otification [H]istory',
    },
    {
      '<leader>nd',
      function()
        Snacks.notifier.hide()
      end,
      desc = '[N]otification [D]ismiss',
    },
    {
      '<leader>gB',
      function()
        Snacks.gitbrowse()
      end,
      desc = 'Open [G]it [B]rowse',
      mode = { 'n', 'v' },
    },
    {
      '<leader>cR',
      function()
        Snacks.rename.rename_file()
      end,
      desc = '[R]ename file',
    },
    {
      ']]',
      function()
        Snacks.words.jump(vim.v.count1)
      end,
      desc = 'Next reference',
      mode = { 'n', 't' },
    },
    {
      '[[',
      function()
        Snacks.words.jump(-vim.v.count1)
      end,
      desc = 'Previous reference',
      mode = { 'n', 't' },
    },
  },
}
