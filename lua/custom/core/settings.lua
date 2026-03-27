local M = {}

local defaults = {
  autoformat = true,
  background = 'dark',
  conceallevel = 0,
  diagnostics = true,
  inlay_hints = false,
  relativenumber = true,
  spell = false,
  wrap = false,
}

local state_path = vim.fs.joinpath(vim.fn.stdpath 'state', 'custom-settings.json')
local state = nil

local function merged(value)
  return vim.tbl_deep_extend('force', vim.deepcopy(defaults), type(value) == 'table' and value or {})
end

local function load_state()
  if state then
    return state
  end

  local file = io.open(state_path, 'r')
  if not file then
    state = merged()
    return state
  end

  local content = file:read '*a'
  file:close()

  local ok, decoded = pcall(vim.json.decode, content)
  state = merged(ok and decoded or nil)
  return state
end

local function save_state()
  vim.fn.mkdir(vim.fn.fnamemodify(state_path, ':h'), 'p')
  vim.fn.writefile({ vim.json.encode(load_state()) }, state_path)
end

local function set_window_option(option, value)
  vim.api.nvim_set_option_value(option, value, { scope = 'global' })
  vim.api.nvim_set_option_value(option, value, { scope = 'local' })
end

function M.get(key, fallback)
  local current = load_state()
  local value = current[key]
  if value == nil then
    return fallback
  end
  return value
end

function M.set(key, value)
  local current = load_state()
  current[key] = value
  save_state()
  return value
end

function M.all()
  return vim.deepcopy(load_state())
end

function M.apply_autoformat(state_value)
  vim.g.autoformat = state_value
end

function M.apply_background(state_value)
  vim.o.background = state_value
end

function M.apply_conceallevel(state_value)
  set_window_option('conceallevel', state_value)
end

function M.apply_diagnostics(state_value)
  if vim.fn.has 'nvim-0.10' == 0 then
    if state_value then
      pcall(vim.diagnostic.enable)
    else
      pcall(vim.diagnostic.disable)
    end
    return
  end

  vim.diagnostic.enable(state_value)
end

function M.apply_inlay_hints(state_value, bufnr)
  if not (vim.lsp and vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable) then
    return
  end

  if bufnr then
    pcall(vim.lsp.inlay_hint.enable, state_value, { bufnr = bufnr })
    return
  end

  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buffer) and next(vim.lsp.get_clients { bufnr = buffer }) ~= nil then
      pcall(vim.lsp.inlay_hint.enable, state_value, { bufnr = buffer })
    end
  end
end

function M.apply_relativenumber(state_value)
  set_window_option('relativenumber', state_value)
end

function M.apply_spell(state_value)
  set_window_option('spell', state_value)
end

function M.apply_wrap(state_value)
  set_window_option('wrap', state_value)
end

function M.apply()
  local current = load_state()
  M.apply_autoformat(current.autoformat)
  M.apply_background(current.background)
  M.apply_conceallevel(current.conceallevel)
  M.apply_diagnostics(current.diagnostics)
  M.apply_inlay_hints(current.inlay_hints)
  M.apply_relativenumber(current.relativenumber)
  M.apply_spell(current.spell)
  M.apply_wrap(current.wrap)
  return current
end

return M
