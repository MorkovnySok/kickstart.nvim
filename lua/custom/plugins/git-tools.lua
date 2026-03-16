return {
  {
    'sindrets/diffview.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    cmd = {
      'DiffviewOpen',
      'DiffviewClose',
      'DiffviewFileHistory',
      'DiffviewFocusFiles',
      'DiffviewToggleFiles',
      'DiffviewRefresh',
    },
    keys = {
      { '<leader>gd', '<cmd>DiffviewOpen<CR>', desc = '[G]it [d]iff view' },
      { '<leader>gc', '<cmd>DiffviewClose<CR>', desc = '[G]it diff [c]lose' },
      { '<leader>gf', '<cmd>DiffviewFileHistory %<CR>', desc = '[G]it [f]ile history' },
    },
    opts = {},
  },
  {
    'akinsho/git-conflict.nvim',
    version = '*',
    event = 'BufReadPre',
    opts = {
      default_mappings = false,
      default_commands = true,
      disable_diagnostics = true,
    },
    keys = {
      { '[x', '<cmd>GitConflictPrevConflict<CR>', desc = 'Git prev conflict' },
      { ']x', '<cmd>GitConflictNextConflict<CR>', desc = 'Git next conflict' },
      { '<leader>go', '<cmd>GitConflictChooseOurs<CR>', desc = 'Conflict choose [o]urs' },
      { '<leader>gt', '<cmd>GitConflictChooseTheirs<CR>', desc = 'Conflict choose [t]heirs' },
      { '<leader>gb', '<cmd>GitConflictChooseBoth<CR>', desc = 'Conflict choose [b]oth' },
      { '<leader>gn', '<cmd>GitConflictChooseNone<CR>', desc = 'Conflict choose [n]one' },
      { '<leader>gq', '<cmd>GitConflictListQf<CR>', desc = 'Conflict list [q]uickfix' },
    },
  },
}
