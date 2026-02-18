vim.api.nvim_set_hl(0, 'TelescopePathTail', { fg = '#569CD6', bold = true })

local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

local function toggle_layout(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  local current = picker.layout_strategy

  picker.layout_strategy = (current == 'vertical') and 'horizontal' or 'vertical'
  picker:full_layout_update()
end

return { -- Fuzzy Finder (files, lsp, etc)
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { -- If encountering errors, see telescope-fzf-native README for installation instructions
      'nvim-telescope/telescope-fzf-native.nvim',

      -- `build` is used to run some command when the plugin is installed/updated.
      -- This is only run then, not every time Neovim starts up.
      build = 'make',

      -- `cond` is a condition used to determine whether this plugin should be
      -- installed and loaded.
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },

    -- Useful for getting pretty icons, but requires a Nerd Font.
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },
  config = function()
    -- [[ Configure Telescope ]]
    -- See `:help telescope` and `:help telescope.setup()`

    local actions = require 'telescope.actions'
    require('telescope').setup {
      -- You can put your default mappings / updates / etc. in here
      --  All the info you're looking for is in `:help telescope.setup()`
      defaults = {
        mappings = {
          i = {
            ['<C-Down>'] = actions.cycle_history_next,
            ['<C-Up>'] = actions.cycle_history_prev,
            ['<C-k>'] = actions.move_selection_previous,
            ['<C-j>'] = actions.move_selection_next,
            ['<C-p>'] = require('telescope.actions.layout').toggle_preview,
            ['<C-g>'] = function(prompt_bufnr)
              local entry = require('telescope.actions.state').get_selected_entry()
              vim.notify(entry.value, vim.log.levels.INFO)
            end,
            ['<C-t>'] = toggle_layout,
          },
          n = {
            ['<C-t>'] = toggle_layout,
          },
        },
        path_display = function(opts, path)
          local tail = require('telescope.utils').path_tail(path)
          return string.format('%s (%s)', tail, path)
        end,
        layout_strategy = 'horizontal',
        layout_config = {
          horizontal = { prompt_position = 'bottom', preview_width = 0.50 },
          vertical = { prompt_position = 'top', mirror = true, preview_height = 0.50 },
          width = 0.95,
          height = 0.80,
          preview_cutoff = 1,
        },
      },
      pickers = {
        lsp_document_symbols = {
          format_item = function(item)
            return string.format('[%s]  %s', item.kind, item.name)
          end,
          fname_width = 60,
          symbol_width = 60,
        },
      },
      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown(),
        },
      },
    }

    local builtin = require 'telescope.builtin'

    local function get_nvim_tree_node_under_cursor()
      local nvim_tree = require 'nvim-tree.api'
      local node = nvim_tree.tree.get_node_under_cursor()
      if node and node.absolute_path then
        return node.fs_stat and node.fs_stat.type == 'directory' and node.absolute_path or vim.fn.fnamemodify(node.absolute_path, ':h')
      end
      return vim.loop.cwd()
    end

    local function smart_search(opts)
      local is_nvim_tree = vim.bo.filetype == 'NvimTree'
      local search_fn = opts.use_live_grep and builtin.live_grep or builtin.find_files

      local search_opts = vim.tbl_extend('force', opts, {
        cwd = is_nvim_tree and get_nvim_tree_node_under_cursor() or nil,
      })

      search_fn(search_opts)
    end

    -- Convenience wrappers
    local function smart_find_files(opts)
      smart_search(vim.tbl_extend('force', opts or {}, { use_live_grep = false }))
    end

    local function smart_live_grep(opts)
      smart_search(vim.tbl_extend('force', opts or {}, { use_live_grep = true }))
    end

    -- Enable Telescope extensions if they are installed
    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')

    -- See `:help telescope.builtin`
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sc', builtin.git_status, { desc = '[S]earch [C]hanges' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
    vim.keymap.set('n', '<leader>sf', smart_find_files, { desc = '[S]earch [F]iles' })
    vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
    vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = 'Search word under cursor everywhere' })
    vim.keymap.set('n', '<leader>SW', function()
      builtin.grep_string {
        cwd = get_nvim_tree_node_under_cursor(),
      }
    end, { desc = '[S]earch current [W]ord in a selected nvim tree node' })
    vim.keymap.set('n', '<leader>se', function()
      local word = vim.fn.expand '<cword>'
      require('telescope.builtin').find_files {
        default_text = word,
      }
    end, { desc = '[S]earch current [W]ord as find files everywhere' })
    vim.keymap.set('n', '<leader>SE', function()
      local word = vim.fn.expand '<cword>'
      require('telescope.builtin').find_files {
        default_text = word,
        cwd = get_nvim_tree_node_under_cursor(),
      }
    end, { desc = '[S]earch current [W]ord as find files in nvim tree dir' })
    vim.keymap.set('n', '<leader>sg', smart_live_grep, { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>SG', function()
      builtin.live_grep {
        cwd = get_nvim_tree_node_under_cursor(),
      }
    end, { desc = '[S]earch by [G]rep in current dir' })
    vim.keymap.set('n', '<leader>SF', function()
      builtin.find_files {
        cwd = get_nvim_tree_node_under_cursor(),
      }
    end, { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
    vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
    vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
    vim.keymap.set('n', '<leader>lS', builtin.lsp_workspace_symbols, { desc = 'Open Workspace Symbols' })

    if vim.g.vscode then
      local function notify(cmd)
        return string.format("<cmd>call VSCodeNotify('%s')<CR>", cmd)
      end

      local function v_notify(cmd)
        return string.format("<cmd>call VSCodeNotifyVisual('%s', 1)<CR>", cmd)
      end

      vim.keymap.set('n', '<Leader>sk', v_notify 'workbench.action.showCommands', { silent = true })
      vim.keymap.set('n', '<Leader>sd', notify 'workbench.actions.view.problems', { silent = true }) -- language diagnostics
      vim.keymap.set('n', '<Leader>sg', notify 'workbench.action.findInFiles', { silent = true }) -- use ripgrep to search files
      vim.keymap.set('n', '<Leader>sh', notify 'workbench.action.toggleAuxiliaryBar', { silent = true }) -- toggle docview (help page)
      vim.keymap.set('n', '<Leader>sf', notify 'workbench.action.quickOpen', { silent = true }) -- find files
      vim.keymap.set('v', '<Leader>sk', v_notify 'workbench.action.showCommands', { silent = true })
    end
    -- Slightly advanced example of overriding default behavior and theme
    vim.keymap.set('n', '<leader>/', function()
      -- You can pass additional configuration to Telescope to change the theme, layout, etc.
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end, { desc = '[/] Fuzzily search in current buffer' })

    -- It's also possible to pass additional configuration options.
    --  See `:help telescope.builtin.live_grep()` for information about particular keys
    vim.keymap.set('n', '<leader>s/', function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end, { desc = '[S]earch [/] in Open Files' })

    -- Shortcut for searching your Neovim configuration files
    vim.keymap.set('n', '<leader>sn', function()
      builtin.find_files { cwd = vim.fn.stdpath 'config' }
    end, { desc = '[S]earch [N]eovim files' })

    vim.keymap.set('n', '<leader>sp', function()
      builtin.find_files { cwd = '~/personal' }
    end, { desc = 'Search Personal' })
  end,
}
