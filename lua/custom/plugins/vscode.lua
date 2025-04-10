local M = {}

if not vim.g.vscode then
  return {}
end

-- local augroup = vim.api.nvim_create_augroup
local keymap = vim.api.nvim_set_keymap

-- M.my_vscode = augroup('MyVSCode', {})

local function notify(cmd)
  return string.format("<cmd>call VSCodeNotify('%s')<CR>", cmd)
end

local function v_notify(cmd)
  return string.format("<cmd>call VSCodeNotifyVisual('%s', 1)<CR>", cmd)
end

keymap('n', '<Leader>gr', notify 'references-view.findReferences', { silent = true }) -- language references
keymap('n', '<Leader>sd', notify 'workbench.actions.view.problems', { silent = true }) -- language diagnostics
keymap('n', 'gr', notify 'editor.action.goToReferences', { silent = true })
keymap('n', '<Leader>lr', notify 'editor.action.rename', { silent = true })
keymap('n', '<Leader>lf', notify 'editor.action.formatDocument', { silent = true })
keymap('n', '<Leader>la', notify 'editor.action.refactor', { silent = true }) -- language code actions

keymap('n', '<Leader>sg', notify 'workbench.action.findInFiles', { silent = true }) -- use ripgrep to search files
keymap('n', '<Leader>ih', notify 'workbench.action.toggleSidebarVisibility', { silent = true })
keymap('n', '<Leader>sh', notify 'workbench.action.toggleAuxiliaryBar', { silent = true }) -- toggle docview (help page)
keymap('n', '<Leader>tp', notify 'workbench.action.togglePanel', { silent = true })
keymap('n', '<Leader>sc', notify 'workbench.action.showCommands', { silent = true }) -- find commands
keymap('n', '<Leader>sf', notify 'workbench.action.quickOpen', { silent = true }) -- find files
keymap('n', '<Leader>it', notify 'workbench.action.terminal.toggleTerminal', { silent = true }) -- terminal window

keymap('v', '<Leader>lf', v_notify 'editor.action.formatSelection', { silent = true })
keymap('v', '<Leader>la', v_notify 'editor.action.refactor', { silent = true })
keymap('v', '<Leader>sc', v_notify 'workbench.action.showCommands', { silent = true })

return M
