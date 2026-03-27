return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  init = function()
    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      callback = function()
        local settings = require 'custom.core.settings'

        local function persistent_bool_toggle(id, name, apply, default)
          return Snacks.toggle {
            id = id,
            name = name,
            get = function()
              return settings.get(id, default)
            end,
            set = function(state)
              settings.set(id, state)
              apply(state)
            end,
          }
        end

        persistent_bool_toggle('autoformat', 'Auto Format', settings.apply_autoformat, true):map '<leader>ua'
        persistent_bool_toggle('spell', 'Spelling', settings.apply_spell, false):map '<leader>us'
        persistent_bool_toggle('wrap', 'Wrap', settings.apply_wrap, false):map '<leader>uw'
        persistent_bool_toggle('relativenumber', 'Relative Number', settings.apply_relativenumber, true):map '<leader>uL'
        persistent_bool_toggle('diagnostics', 'Diagnostics', settings.apply_diagnostics, true):map '<leader>ud'
        Snacks.toggle.line_number():map '<leader>ul'
        Snacks.toggle {
          id = 'conceallevel',
          name = 'Conceal',
          get = function()
            return settings.get('conceallevel', 0) > 0
          end,
          set = function(state)
            local value = state and 2 or 0
            settings.set('conceallevel', value)
            settings.apply_conceallevel(value)
          end,
        }:map '<leader>uc'
        Snacks.toggle.treesitter():map '<leader>uT'
        Snacks.toggle {
          id = 'background',
          name = 'Dark Background',
          get = function()
            return settings.get('background', 'dark') == 'dark'
          end,
          set = function(state)
            local value = state and 'dark' or 'light'
            settings.set('background', value)
            settings.apply_background(value)
          end,
        }:map '<leader>ub'
        persistent_bool_toggle('inlay_hints', 'Inlay Hints', settings.apply_inlay_hints, false):map '<leader>uh'
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
