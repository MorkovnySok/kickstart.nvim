local buffer_dir = '/mnt/c/Users/Artem.Vasilev/Desktop/buffer/'

function CopyToBufferAndOpen()
  local current_file = vim.fn.expand '%:p' -- Get full path of current file
  local file_name = vim.fn.expand '%:t' -- Get just the filename

  -- Create buffer directory if it doesn't exist
  if vim.fn.isdirectory(buffer_dir) == 0 then
    vim.fn.mkdir(buffer_dir, 'p')
  end

  local destination = buffer_dir .. file_name

  -- Copy file to buffer directory
  local copy_cmd = string.format('cp "%s" "%s"', current_file, destination)
  os.execute(copy_cmd)

  -- Open with wslview
  local open_cmd = string.format('wslview "%s"', destination)
  os.execute(open_cmd)

  vim.notify('Copied to buffer and opened with wslview: ' .. destination)
end
vim.keymap.set('n', '<leader>fxo', CopyToBufferAndOpen, { desc = '[F]ile copy to buffer and open with wslview', silent = true })

function UpdateFromBuffer()
  local current_file = vim.fn.expand '%:p' -- Get full path of current file
  local file_name = vim.fn.expand '%:t' -- Get just the filename
  local buffer_dir = '/mnt/c/users/artem.vasilev/desktop/buffer/'
  local buffer_file = buffer_dir .. file_name

  -- Check if buffer file exists
  if vim.fn.filereadable(buffer_file) == 0 then
    vim.notify('No corresponding file found in buffer directory: ' .. buffer_file, vim.log.levels.ERROR)
    return
  end

  -- Copy file back from buffer
  local copy_cmd = string.format('cp "%s" "%s"', buffer_file, current_file)
  os.execute(copy_cmd)

  -- Reload the file in Vim
  vim.cmd 'edit!'

  vim.notify('File updated from buffer: ' .. buffer_file)
end

vim.keymap.set('n', '<leader>fxu', UpdateFromBuffer, { desc = '[F]ile update from buffer', silent = true })
vim.keymap.set('n', '<leader>fxl', function()
  local path = vim.fn.expand '%'
  vim.system { 'libreoffice', path }
end, { desc = '[F]ile update from buffer', silent = true })

return {}
