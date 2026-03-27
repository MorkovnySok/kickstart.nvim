return {
  {
    'nvimtools/none-ls.nvim',
    config = function()
      local nls = require 'null-ls'
      nls.setup {
        sources = {
          -- nls.builtins.formatting.prettier.with {
          --   disabled_filetypes = { 'markdown', 'markdown.mdx' },
          -- },
          nls.builtins.formatting.stylua,
        },
        disabled_filetypes = { 'markdown' },
      }
    end,
  },
  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>lf',
        function()
          require('custom.format').format()
        end,
        mode = { 'n', 'v' },
        desc = '[F]ormat buffer/selection',
      },
    },
    opts = function()
      local uv = vim.uv or vim.loop
      local conform_util = require 'conform.util'
      local prettier_cwd = require('conform.formatters.prettierd').cwd
      local prettier = { 'prettier' }

      local function cleanup_temp_file(path)
        if uv.fs_stat(path) then
          uv.fs_unlink(path)
        end
      end

      local function run_prettier_via_tempfile(self, ctx, input_lines, callback)
        local command = vim.fn.exepath 'prettier'
        if command == '' then
          callback 'prettier executable not found'
          return
        end

        local temp_file = vim.fs.joinpath(ctx.dirname, string.format('.conform.%d.%s', math.random(1000000, 9999999), vim.fs.basename(ctx.filename)))
        local lines = vim.deepcopy(input_lines)
        local add_extra_newline = vim.bo[ctx.buf].eol
        if add_extra_newline then
          table.insert(lines, '')
        end

        local fd = assert(uv.fs_open(temp_file, 'w', 448)) -- 0700
        uv.fs_write(fd, table.concat(lines, '\n'))
        uv.fs_close(fd)

        local args = { '--write' }
        if ctx.range then
          local start_offset, end_offset = conform_util.get_offsets_from_range(ctx.buf, ctx.range)
          table.insert(args, '--range-start=' .. start_offset)
          table.insert(args, '--range-end=' .. end_offset)
        end
        table.insert(args, temp_file)

        local result = vim.system(vim.list_extend({ command }, args), {
          cwd = prettier_cwd(self, ctx),
          text = true,
        }):wait()

        if result.code ~= 0 then
          cleanup_temp_file(temp_file)
          callback(result.stderr ~= '' and result.stderr or result.stdout ~= '' and result.stdout or 'prettier failed')
          return
        end

        local read_fd = assert(uv.fs_open(temp_file, 'r', 448))
        local stat = assert(uv.fs_fstat(read_fd))
        local content = uv.fs_read(read_fd, stat.size, 0) or ''
        uv.fs_close(read_fd)
        cleanup_temp_file(temp_file)

        local output = vim.split(content, '\r?\n')
        if add_extra_newline and output[#output] == '' then
          table.remove(output)
        end
        if #output == 0 then
          output = { '' }
        end

        callback(nil, output)
      end

      local function has_astro_prettier_plugin(bufnr)
        local filename = vim.api.nvim_buf_get_name(bufnr)
        if filename == '' then
          return false
        end

        local dirname = vim.fs.dirname(filename)
        return vim.fs.find('node_modules/prettier-plugin-astro/package.json', { upward = true, path = dirname })[1] ~= nil
      end

      return {
        notify_on_error = false,
        format_on_save = function(bufnr)
          if vim.g.autoformat == false or vim.b[bufnr].autoformat == false then
            return nil
          end

          -- Disable "format_on_save lsp_fallback" for languages that don't
          -- have a well standardized coding style. You can add additional
          -- languages here or re-enable it for the disabled ones.
          local disable_filetypes = { c = true, cpp = true }
          if disable_filetypes[vim.bo[bufnr].filetype] then
            return nil
          else
            return {
              timeout_ms = 500,
              lsp_format = 'fallback',
            }
          end
        end,
        formatters = {
          prettier = {
            format = run_prettier_via_tempfile,
          },
        },
        formatters_by_ft = {
          astro = function(bufnr)
            if has_astro_prettier_plugin(bufnr) then
              return prettier
            end

            return {}
          end,
          css = prettier,
          graphql = prettier,
          handlebars = prettier,
          html = prettier,
          javascript = prettier,
          javascriptreact = prettier,
          json = prettier,
          jsonc = prettier,
          less = prettier,
          lua = { 'stylua' },
          markdown = prettier,
          scss = prettier,
          typescript = prettier,
          typescriptreact = prettier,
          yaml = prettier,
        },
      }
    end,
  },
}
