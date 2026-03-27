local M = {}

function M.format()
  require('conform').format({ async = true, lsp_format = 'fallback' }, function(err)
    if err then
      return
    end

    local mode = vim.api.nvim_get_mode().mode
    if vim.startswith(string.lower(mode), 'v') then
      vim.api.nvim_feedkeys(vim.keycode '<Esc>', 'n', true)
    end
  end)
end

return M
