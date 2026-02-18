local M = {
  _ready = false,
}

local function map(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, {
    silent = true,
    desc = desc,
  })
end

function M.setup(opts)
  opts = opts or {}

  if M._ready and not opts.force then
    return M
  end

  map('<leader>Ag', '<cmd>AdinsureGoto<CR>', '[A]dInsure [G]oto')
  map('<leader>Af', '<cmd>AdinsureFlow<CR>', '[A]dInsure [F]low')
  map('<leader>At', '<cmd>AdinsureContextTrace<CR>', '[A]dInsure Context [T]race')
  map('<leader>Ap', '<cmd>AdinsureInsertJSDocPartial<CR>', '[A]dInsure JSDoc [P]artial')
  map('<leader>Ai', '<cmd>AdinsureInputProps<CR>', '[A]dInsure [I]nput props')
  map('<leader>Aj', '<cmd>AdinsureInsertJSDoc<CR>', '[A]dInsure Insert [J]SDoc')
  map('<leader>AJ', '<cmd>AdinsureGenerateJSDoc<CR>', '[A]dInsure Generate [J]SDoc')

  M._ready = true
  return M
end

return M
