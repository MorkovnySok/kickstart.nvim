return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'rcarriga/nvim-dap-ui',
      'nvim-neotest/nvim-nio',
      {
        'microsoft/vscode-js-debug',
        build = 'npm ci --ignore-scripts --legacy-peer-deps && npx gulp vsDebugServerBundle',
        version = '1.*',
      },
    },
    keys = {
      {
        '<F5>',
        function()
          require('dap').continue()
        end,
        desc = 'Debug: Start/Continue',
      },
      {
        '<F10>',
        function()
          require('dap').step_over()
        end,
        desc = 'Debug: Step Over',
      },
      {
        '<F11>',
        function()
          require('dap').step_into()
        end,
        desc = 'Debug: Step Into',
      },
      {
        '<F12>',
        function()
          require('dap').step_out()
        end,
        desc = 'Debug: Step Out',
      },
      {
        '<leader>db',
        function()
          require('dap').toggle_breakpoint()
        end,
        desc = 'Debug: Toggle Breakpoint',
      },
      {
        '<leader>dB',
        function()
          require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end,
        desc = 'Debug: Conditional Breakpoint',
      },
      {
        '<leader>du',
        function()
          require('dapui').toggle()
        end,
        desc = 'Debug: Toggle UI',
      },
      {
        '<leader>dr',
        function()
          require('dap').repl.toggle()
        end,
        desc = 'Debug: Toggle REPL',
      },
      {
        '<leader>dh',
        function()
          require('dap.ui.widgets').hover()
        end,
        desc = 'Debug: Hover',
        mode = { 'n', 'v' },
      },
      {
        '<leader>dt',
        function()
          require('dap').terminate()
        end,
        desc = 'Debug: Terminate',
      },
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'
      local debugger_path = vim.fn.stdpath 'data' .. '/lazy/vscode-js-debug/dist/src/vsDebugServer.js'

      dapui.setup {
        icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
        controls = {
          icons = {
            pause = '⏸',
            play = '▶',
            step_into = '⏎',
            step_over = '⏭',
            step_out = '⏮',
            step_back = 'b',
            run_last = '▶▶',
            terminate = '⏹',
            disconnect = '⏏',
          },
        },
      }

      dap.adapters['pwa-node'] = {
        type = 'server',
        host = '127.0.0.1',
        port = '${port}',
        executable = {
          command = 'node',
          args = {
            debugger_path,
            '${port}',
          },
        },
      }

      local js_filetypes = {
        'javascript',
        'javascriptreact',
        'typescript',
        'typescriptreact',
      }

      for _, language in ipairs(js_filetypes) do
        dap.configurations[language] = {
          {
            type = 'pwa-node',
            request = 'launch',
            name = 'Debug current file',
            cwd = '${workspaceFolder}',
            program = '${file}',
            console = 'integratedTerminal',
            skipFiles = {
              '<node_internals>/**',
            },
          },
          {
            type = 'pwa-node',
            request = 'launch',
            name = 'Debug scratch/22830',
            cwd = '${workspaceFolder}',
            program = '${workspaceFolder}/scratch/22830/debug.js',
            console = 'integratedTerminal',
            skipFiles = {
              '<node_internals>/**',
            },
          },
          {
            type = 'pwa-node',
            request = 'attach',
            name = 'Attach to Node process',
            cwd = '${workspaceFolder}',
            processId = require('dap.utils').pick_process,
            skipFiles = {
              '<node_internals>/**',
            },
          },
          {
            type = 'pwa-node',
            request = 'attach',
            name = 'Attach to Node 9229',
            cwd = '${workspaceFolder}',
            port = 9229,
            restart = true,
            skipFiles = {
              '<node_internals>/**',
            },
          },
        }
      end

      dap.listeners.after.event_initialized.dapui_autoopen = function()
        dapui.open()
      end

      dap.listeners.before.event_terminated.dapui_autoclose = function()
        dapui.close()
      end

      dap.listeners.before.event_exited.dapui_autoclose = function()
        dapui.close()
      end
    end,
  },
}
