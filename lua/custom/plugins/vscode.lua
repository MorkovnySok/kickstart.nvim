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

-- New Git keymaps (from your original config)
keymap('n', '<Leader>gB', notify 'git.branches', { silent = true }) -- View all branches
keymap('n', '<Leader>gb', notify 'git.createBranch', { silent = true }) -- Create new branch
keymap('n', '<Leader>gp', notify 'git.pull', { silent = true }) -- Git pull
keymap('n', '<Leader>gP', notify 'git.push', { silent = true }) -- Git push
keymap('n', '<Leader>gt', notify 'workbench.view.scm', { silent = true }) -- Show Git panel
keymap('n', '<Leader>gs', notify 'workbench.scm.focus', { silent = true }) -- Focus SCM view
-- keymap('n', '<Leader>ga', notify 'git.stageAll', { silent = true }) -- Stage all changes
keymap('n', '<Leader>gd', notify 'git.openChange', { silent = true }) -- View diff
keymap('n', '<Leader>ge', notify 'workbench.action.editor.nextChange', { silent = true }) -- Next change
keymap('n', 'ge', notify 'workbench.action.editor.nextChange', { silent = true }) -- Next error/change

-- Additional useful Git commands
-- keymap('n', '<Leader>gc', notify 'git.commit', { silent = true }) -- Git commit
-- keymap('n', '<Leader>gC', notify 'git.commitAll', { silent = true }) -- Git commit all
-- keymap('n', '<Leader>gu', notify 'git.unstage', { silent = true }) -- Git unstage
-- keymap('n', '<Leader>gR', notify 'git.revertChange', { silent = true }) -- Git revert change
-- keymap('n', '<Leader>gl', notify 'git.showOutput', { silent = true }) -- Show Git log

-- Optional GitLens keymaps
keymap('n', '<Leader>gh', notify 'gitlens.showQuickRepoHistory', { silent = true }) -- File history
keymap('n', '<Leader>gH', notify 'gitlens.showQuickFileHistory', { silent = true }) -- Line history
keymap('n', '<Leader>ga', notify 'gitlens.toggleFileBlame', { silent = true }) -- Toggle blame

-- explorer
keymap('n', '<Leader>ef', notify 'workbench.files.action.showActiveFileInExplorer', { silent = true }) -- show in file explorer
keymap('n', '<Leader>fc', '<cmd>normal! viw<CR><cmd>call VSCodeNotify("workbench.action.findInFiles")<CR>', { silent = true })

return M
