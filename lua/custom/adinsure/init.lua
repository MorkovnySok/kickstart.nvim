local uv = vim.uv or vim.loop
local defaults = require 'custom.adinsure.mappings'

local M = {
  _ready = false,
  _resolvers = {},
  _opts = {},
}

local function path_exists(path)
  return uv.fs_stat(path) ~= nil
end

local function dirname(path)
  return vim.fs.dirname(path)
end

local function workspace_root(path)
  return vim.fs.root(path, { '.git', 'configuration' }) or vim.fn.getcwd()
end

local function dedupe(paths)
  local seen = {}
  local out = {}

  for _, p in ipairs(paths or {}) do
    if p and p ~= '' and not seen[p] then
      seen[p] = true
      table.insert(out, p)
    end
  end

  table.sort(out)
  return out
end

local function to_relative(path, root)
  if root and root ~= '' then
    local prefix = root .. '/'
    if path:sub(1, #prefix) == prefix then
      return path:sub(#prefix + 1)
    end
  end

  return vim.fn.fnamemodify(path, ':~')
end

local function glob_kind(kind, symbol, root)
  local patterns = M._opts.kind_patterns[kind] or {}
  local out = {}

  for _, pattern in ipairs(patterns) do
    local full_pattern = root .. '/' .. string.format(pattern, symbol)
    local matches = vim.fn.glob(full_pattern, false, true)
    for _, p in ipairs(matches) do
      table.insert(out, p)
    end
  end

  return dedupe(out)
end

local function pick_with_telescope(paths, prompt, root)
  local ok_pickers, pickers = pcall(require, 'telescope.pickers')
  if not ok_pickers then
    return false
  end

  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  local picker_opts = vim.tbl_deep_extend('force', {
    prompt_title = prompt or 'AdInsure targets',
    finder = finders.new_table {
      results = paths,
      entry_maker = function(path)
        return {
          value = path,
          ordinal = path,
          display = to_relative(path, root),
          path = path,
        }
      end,
    },
    previewer = conf.file_previewer {},
    sorter = conf.generic_sorter {},
    attach_mappings = function(_, _)
      actions.select_default:replace(function(bufnr)
        local selection = action_state.get_selected_entry()
        actions.close(bufnr)
        if selection and selection.value then
          vim.cmd('edit ' .. vim.fn.fnameescape(selection.value))
        end
      end)
      return true
    end,
  }, M._opts.telescope_picker or {})

  pickers.new({}, picker_opts):find()
  return true
end

local function pick_or_open(paths, prompt, root)
  local uniq = dedupe(paths)

  if #uniq == 0 then
    return false
  end

  if #uniq == 1 then
    vim.cmd('edit ' .. vim.fn.fnameescape(uniq[1]))
    return true
  end

  if M._opts.use_telescope_picker and pick_with_telescope(uniq, prompt, root) then
    return true
  end

  vim.ui.select(uniq, {
    prompt = prompt or 'Select target',
    format_item = function(item)
      return to_relative(item, root)
    end,
  }, function(choice)
    if choice then
      vim.cmd('edit ' .. vim.fn.fnameescape(choice))
    end
  end)

  return true
end

local function line_value(line, key)
  return line:match('"' .. key .. '"%s*:%s*"([^"]+)"')
end

local function lines_before(buf, lnum, count)
  local start_lnum = math.max(1, lnum - count)
  return vim.api.nvim_buf_get_lines(buf, start_lnum - 1, lnum, false)
end

local function infer_kind_from_context(buf, lnum)
  local joined = table.concat(lines_before(buf, lnum, 25), '\n')

  for ctx_key, kind in pairs(M._opts.context_key_to_kind) do
    if joined:find('"' .. ctx_key .. '"%s*:') then
      return kind
    end
  end

  return nil
end

local function step_artifacts_for(file, step_name)
  local base = dirname(file) .. '/sinkMappings/' .. step_name
  local out = {}

  for _, name in ipairs(M._opts.step_artifacts) do
    local candidate = base .. '/' .. name
    if path_exists(candidate) then
      table.insert(out, candidate)
    end
  end

  return out
end

local function build_context()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  local line = vim.api.nvim_get_current_line()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]

  return {
    bufnr = buf,
    file = file,
    line = line,
    lnum = lnum,
    cword = vim.fn.expand '<cword>',
    root = workspace_root(file),
  }
end

local function add_default_resolvers()
  M.register_resolver('step_artifacts', function(ctx)
    if not ctx.file:match '/configuration/' or not ctx.file:match '/configuration%.json$' then
      return nil
    end

    local step = line_value(ctx.line, 'name')
    if not step then
      return nil
    end

    local targets = step_artifacts_for(ctx.file, step)
    if #targets == 0 then
      return nil
    end

    return {
      prompt = 'AdInsure step: ' .. step,
      paths = targets,
    }
  end)

  M.register_resolver('direct_keys', function(ctx)
    for key, kind in pairs(M._opts.direct_key_to_kind) do
      local symbol = line_value(ctx.line, key)
      if symbol then
        return {
          prompt = string.format('AdInsure %s: %s', kind, symbol),
          paths = glob_kind(kind, symbol, ctx.root),
        }
      end
    end

    return nil
  end)

  M.register_resolver('configuration_name_context', function(ctx)
    local symbol = line_value(ctx.line, 'name')
    if not symbol then
      return nil
    end

    local kind = infer_kind_from_context(ctx.bufnr, ctx.lnum)
    if not kind then
      return nil
    end

    return {
      prompt = string.format('AdInsure %s: %s', kind, symbol),
      paths = glob_kind(kind, symbol, ctx.root),
    }
  end)
end

local function load_user_options()
  local ok, user_opts = pcall(require, 'custom.adinsure.user')
  if ok and type(user_opts) == 'table' then
    return user_opts
  end

  return {}
end

function M.register_kind(kind, patterns)
  M._opts.kind_patterns[kind] = patterns
end

function M.register_resolver(name, fn)
  table.insert(M._resolvers, {
    name = name,
    run = fn,
  })
end

function M.goto_definition(opts)
  opts = opts or {}

  if not M._ready then
    M.setup()
  end

  local ctx = build_context()

  for _, resolver in ipairs(M._resolvers) do
    local ok, result = pcall(resolver.run, ctx)

    if ok and result and result.paths and #result.paths > 0 then
      if pick_or_open(result.paths, result.prompt, ctx.root) then
        return true
      end
    end
  end

  if type(opts.fallback) == 'function' then
    opts.fallback()
    return true
  end

  return false
end

function M.setup(opts)
  if M._ready then
    return M
  end

  M._opts = vim.tbl_deep_extend('force', defaults, load_user_options(), opts or {})
  add_default_resolvers()

  if type(M._opts.on_setup) == 'function' then
    M._opts.on_setup(M)
  end

  vim.api.nvim_create_user_command('AdinsureGoto', function()
    M.goto_definition {
      fallback = function()
        vim.cmd 'normal! gd'
      end,
    }
  end, { desc = 'AdInsure goto definition' })

  M._ready = true
  return M
end

return M
