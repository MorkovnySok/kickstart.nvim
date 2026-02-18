local uv = vim.uv or vim.loop
local defaults = require 'custom.adinsure.mappings'

local M = {
  _ready = false,
  _resolvers = {},
  _opts = {},
  _cache = {
    schema_candidates = {},
    ref_callers = {},
  },
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

local function dedupe(paths, keep_order)
  local seen = {}
  local out = {}

  for _, p in ipairs(paths or {}) do
    if p and p ~= '' and not seen[p] then
      seen[p] = true
      table.insert(out, p)
    end
  end

  if not keep_order then
    table.sort(out)
  end

  return out
end

local function sorted_keys(set_like)
  local out = {}

  for key in pairs(set_like or {}) do
    table.insert(out, key)
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

local function read_lines(path)
  if not path or path == '' or not path_exists(path) then
    return {}
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if ok and type(lines) == 'table' then
    return lines
  end

  return {}
end

local function decode_json_file(path)
  local lines = read_lines(path)
  if #lines == 0 then
    return nil
  end

  local ok, data = pcall(vim.json.decode, table.concat(lines, '\n'))
  if ok and type(data) == 'table' then
    return data
  end

  return nil
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

local function pick_records_with_telescope(records, prompt)
  local ok_pickers, pickers = pcall(require, 'telescope.pickers')
  if not ok_pickers then
    return false
  end

  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  local picker_opts = vim.tbl_deep_extend('force', {
    prompt_title = prompt or 'AdInsure flow',
    finder = finders.new_table {
      results = records,
      entry_maker = function(item)
        return {
          value = item,
          ordinal = item.ordinal or item.label or item.path,
          display = item.label or item.path,
          path = item.path,
        }
      end,
    },
    previewer = conf.file_previewer {},
    sorter = conf.generic_sorter {},
    attach_mappings = function(_, _)
      actions.select_default:replace(function(bufnr)
        local selection = action_state.get_selected_entry()
        actions.close(bufnr)
        if selection and selection.value and selection.value.path then
          vim.cmd('edit ' .. vim.fn.fnameescape(selection.value.path))
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

local function pick_records_or_open(records, prompt)
  if #records == 0 then
    return false
  end

  if #records == 1 then
    vim.cmd('edit ' .. vim.fn.fnameescape(records[1].path))
    return true
  end

  if M._opts.use_telescope_picker and pick_records_with_telescope(records, prompt) then
    return true
  end

  vim.ui.select(records, {
    prompt = prompt or 'Select target',
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if choice and choice.path then
      vim.cmd('edit ' .. vim.fn.fnameescape(choice.path))
    end
  end)

  return true
end

local function open_full_width_scratch(lines, title)
  local cfg = M._opts.context_trace_window or {}
  local width_ratio = tonumber(cfg.width) or 0.99
  local height_ratio = tonumber(cfg.height) or 0.80
  local border = cfg.border or 'rounded'

  local total_cols = vim.o.columns
  local total_rows = vim.o.lines - vim.o.cmdheight

  local width = math.max(70, math.floor(total_cols * width_ratio))
  local height = math.max(12, math.floor(total_rows * height_ratio))

  width = math.min(width, total_cols - 2)
  height = math.min(height, total_rows - 2)

  local row = math.max(0, math.floor((total_rows - height) / 2) - 1)
  local col = math.max(0, math.floor((total_cols - width) / 2))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true
  vim.bo[buf].filetype = 'adinsure-trace'

  local body = {}
  if title and title ~= '' then
    table.insert(body, title)
    table.insert(body, string.rep('=', #title))
    table.insert(body, '')
  end

  for _, line in ipairs(lines or {}) do
    table.insert(body, line)
  end

  if #body == 0 then
    table.insert(body, 'No data')
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, body)
  vim.bo[buf].modifiable = false

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    style = 'minimal',
    border = border,
    width = width,
    height = height,
    row = row,
    col = col,
  })

  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true

  vim.keymap.set('n', 'q', function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, silent = true, nowait = true })
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

local function step_artifacts_for(file, step_name, artifact_names)
  local base = dirname(file) .. '/sinkMappings/' .. step_name
  local out = {}

  for _, name in ipairs(artifact_names or M._opts.step_artifacts or {}) do
    local candidate = base .. '/' .. name
    if path_exists(candidate) then
      table.insert(out, candidate)
    end
  end

  return dedupe(out, true)
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

local function owner_configuration_file(file)
  if not file or file == '' then
    return nil
  end

  if file:match '/configuration%.json$' then
    return file
  end

  local owner = file:match '^(.*)/sinkMappings/[^/]+/.*$'
  if owner then
    return owner .. '/configuration.json'
  end

  owner = file:match '^(.*)/sinkMappings/[^/]+$'
  if owner then
    return owner .. '/configuration.json'
  end

  return nil
end

local function find_line_with_key_value(lines, key, value, start_lnum)
  if not value or value == '' then
    return nil
  end

  local pattern = '"' .. key .. '"%s*:%s*"' .. vim.pesc(value) .. '"'
  local from = math.max(1, tonumber(start_lnum) or 1)

  for idx = from, #lines do
    if lines[idx]:match(pattern) then
      return idx
    end
  end

  return nil
end

local function extract_sink_steps(config_path)
  local data = decode_json_file(config_path)
  if type(data) ~= 'table' or type(data.sinks) ~= 'table' then
    return {}
  end

  local lines = read_lines(config_path)
  local search_from = 1
  local out = {}

  for idx, sink in ipairs(data.sinks) do
    if type(sink) == 'table' then
      local name = sink.name
      if type(name) ~= 'string' or name == '' then
        name = string.format('step_%02d', idx)
      end

      local ref = nil
      if type(sink.ref) == 'string' and sink.ref ~= '' then
        ref = sink.ref
      end

      local name_lnum = find_line_with_key_value(lines, 'name', name, search_from)
      local ref_lnum = nil
      if ref then
        ref_lnum = find_line_with_key_value(lines, 'ref', ref, name_lnum or search_from)
      end

      local last_lnum = ref_lnum or name_lnum or search_from
      search_from = math.min(#lines + 1, last_lnum + 1)

      table.insert(out, {
        index = idx,
        name = name,
        ref = ref,
        name_lnum = name_lnum,
        ref_lnum = ref_lnum,
        raw = sink,
      })
    end
  end

  return out
end

local function normalize_context_key(raw)
  if not raw or raw == '' then
    return nil
  end

  return raw:match '^([%w_]+)'
end

local function capture_pattern_keys(line, pattern, set)
  for raw in line:gmatch(pattern) do
    local key = normalize_context_key(raw)
    if key and key ~= '' then
      set[key] = true
    end
  end
end

local function context_keys_from_line(line, mode)
  local vars = M._opts.context_variables or {}
  local out = {}

  for _, var in ipairs(vars) do
    local scoped = '%f[%w_]' .. var .. '%f[^%w_]'

    if mode == 'read' then
      capture_pattern_keys(line, scoped .. '%.([%w_]+)', out)
      capture_pattern_keys(line, scoped .. "%[['\"]([%w_]+)['\"]%]", out)
      capture_pattern_keys(line, '[%w_%.]+%.get%(%s*' .. scoped .. "%s*,%s*['\"]([%w_%.]+)['\"]", out)
      capture_pattern_keys(line, '[%w_%.]+%.has%(%s*' .. scoped .. "%s*,%s*['\"]([%w_%.]+)['\"]", out)
    else
      capture_pattern_keys(line, scoped .. '%.([%w_]+)%s*=', out)
      capture_pattern_keys(line, scoped .. "%[['\"]([%w_]+)['\"]%]%s*=", out)
      capture_pattern_keys(line, '[%w_%.]+%.set%(%s*' .. scoped .. "%s*,%s*['\"]([%w_%.]+)['\"]", out)
    end
  end

  return sorted_keys(out)
end

local function collect_context_signals(config_path, steps)
  local artifacts = M._opts.context_trace_artifacts or { 'mapping.js', 'apply.js' }
  local signals = {}
  local seen = {}

  for _, step in ipairs(steps) do
    local files = step_artifacts_for(config_path, step.name, artifacts)

    for _, path in ipairs(files) do
      local artifact = vim.fn.fnamemodify(path, ':t')
      local lines = read_lines(path)

      for lnum, line in ipairs(lines) do
        local reads = context_keys_from_line(line, 'read')
        local writes = context_keys_from_line(line, 'write')

        for _, key in ipairs(reads) do
          local id = table.concat({ path, tostring(lnum), key, 'read' }, ':')
          if not seen[id] then
            seen[id] = true
            table.insert(signals, {
              step = step.name,
              step_index = step.index,
              artifact = artifact,
              mode = 'read',
              key = key,
              file = path,
              lnum = lnum,
              text = vim.trim(line),
            })
          end
        end

        for _, key in ipairs(writes) do
          local id = table.concat({ path, tostring(lnum), key, 'write' }, ':')
          if not seen[id] then
            seen[id] = true
            table.insert(signals, {
              step = step.name,
              step_index = step.index,
              artifact = artifact,
              mode = 'write',
              key = key,
              file = path,
              lnum = lnum,
              text = vim.trim(line),
            })
          end
        end
      end
    end
  end

  table.sort(signals, function(a, b)
    if a.step_index ~= b.step_index then
      return a.step_index < b.step_index
    end
    if a.file ~= b.file then
      return a.file < b.file
    end
    if a.lnum ~= b.lnum then
      return a.lnum < b.lnum
    end
    if a.mode ~= b.mode then
      return a.mode < b.mode
    end
    return a.key < b.key
  end)

  return signals
end

local function build_context_summary_lines(config_path, steps, signals, root)
  local per_step = {}

  for _, step in ipairs(steps) do
    per_step[step.name] = {
      reads = {},
      writes = {},
      index = step.index,
    }
  end

  for _, signal in ipairs(signals) do
    local slot = per_step[signal.step]
    if not slot then
      slot = {
        reads = {},
        writes = {},
        index = signal.step_index,
      }
      per_step[signal.step] = slot
    end

    if signal.mode == 'write' then
      slot.writes[signal.key] = true
    else
      slot.reads[signal.key] = true
    end
  end

  local lines = {
    'Config: ' .. to_relative(config_path, root),
    '',
  }

  if #steps == 0 then
    table.insert(lines, 'No sinks found in this configuration.')
    return lines
  end

  for _, step in ipairs(steps) do
    local slot = per_step[step.name] or { reads = {}, writes = {} }
    local reads = sorted_keys(slot.reads)
    local writes = sorted_keys(slot.writes)

    table.insert(lines, string.format('[%02d] %s', step.index, step.name))
    table.insert(lines, '  writes: ' .. (#writes > 0 and table.concat(writes, ', ') or 'none'))
    table.insert(lines, '  reads:  ' .. (#reads > 0 and table.concat(reads, ', ') or 'none'))
    table.insert(lines, '')
  end

  return lines
end

local function collect_sinkgroup_flow(config_path, root)
  local records = {}
  local unresolved = 0
  local visited = {}
  local max_depth = tonumber(M._opts.flow_max_depth) or 12

  local function walk(file, depth)
    if depth > max_depth then
      return
    end

    local steps = extract_sink_steps(file)

    for _, step in ipairs(steps) do
      if step.ref and step.ref ~= '' then
        local targets = glob_kind('sinkGroup', step.ref, root)

        if #targets == 0 then
          unresolved = unresolved + 1
          if M._opts.flow_show_missing then
            table.insert(records, {
              depth = depth,
              step_index = step.index,
              step_name = step.name,
              ref = step.ref,
              source = file,
              missing = true,
            })
          end
        else
          for _, target in ipairs(targets) do
            table.insert(records, {
              depth = depth,
              step_index = step.index,
              step_name = step.name,
              ref = step.ref,
              source = file,
              path = target,
              missing = false,
            })
          end

          for _, target in ipairs(targets) do
            if not visited[target] then
              visited[target] = true
              walk(target, depth + 1)
            end
          end
        end
      end
    end
  end

  visited[config_path] = true
  walk(config_path, 0)

  return records, unresolved
end

local function flow_record_label(record, root)
  local indent = string.rep('  ', math.max(0, tonumber(record.depth) or 0))
  local prefix = string.format('%s[%02d] %s -> %s', indent, record.step_index or 0, record.step_name or '?', record.ref or '?')

  if record.missing then
    return prefix .. ' (missing)'
  end

  return prefix .. ' | ' .. to_relative(record.path, root)
end

local function shared_prefix_len(a, b)
  if not a or not b then
    return 0
  end

  local max_len = math.min(#a, #b)
  local idx = 0

  while idx < max_len and a:sub(idx + 1, idx + 1) == b:sub(idx + 1, idx + 1) do
    idx = idx + 1
  end

  return idx
end

local function best_path_match(paths, prefer_prefix)
  local best = nil
  local best_score = -1

  for _, path in ipairs(paths or {}) do
    local score = 0
    if prefer_prefix and prefer_prefix ~= '' then
      score = shared_prefix_len(path, prefer_prefix)
    end

    if score > best_score or (score == best_score and (not best or #path < #best)) then
      best_score = score
      best = path
    end
  end

  return best
end

local function schema_candidates_for(config_path, current_file)
  local names = M._opts.input_props_schema_candidates or { 'inputSchema.json', 'messageSchema.json', 'dataSchema.json' }
  local include_callers = not not M._opts.input_props_include_callers
  local max_depth = tonumber(M._opts.input_props_callers_max_depth) or 3
  local max_configs = tonumber(M._opts.input_props_callers_max_configs) or 40

  local step = current_file and current_file:match '/sinkMappings/([^/]+)/' or ''
  local cache_key = table.concat({
    config_path or '',
    step or '',
    tostring(include_callers),
    tostring(max_depth),
    tostring(max_configs),
  }, '|')

  if M._cache.schema_candidates[cache_key] then
    return vim.deepcopy(M._cache.schema_candidates[cache_key])
  end

  local out = {}
  local seen_files = {}

  local function add_if_exists(path)
    if path_exists(path) and not seen_files[path] then
      seen_files[path] = true
      table.insert(out, path)
    end
  end

  local function add_local_candidates(owner_config, source_file)
    local owner_dir = dirname(owner_config)

    for _, name in ipairs(names) do
      add_if_exists(owner_dir .. '/' .. name)
    end

    local step_name = source_file and source_file:match '/sinkMappings/([^/]+)/'
    if step_name then
      local step_dir = owner_dir .. '/sinkMappings/' .. step_name
      for _, name in ipairs(names) do
        add_if_exists(step_dir .. '/' .. name)
      end
    end
  end

  local function sinkgroup_name_from_config(path)
    return path and path:match '/sinkGroup/([^/]+)/configuration%.json$'
  end

  local function scan_ref_callers(ref_name, root, current_config)
    if not ref_name or ref_name == '' then
      return {}
    end

    local caller_key = table.concat({ root or '', ref_name }, '|')
    if M._cache.ref_callers[caller_key] then
      local cached = M._cache.ref_callers[caller_key]
      local filtered = {}
      for _, path in ipairs(cached) do
        if path ~= current_config then
          table.insert(filtered, path)
        end
      end
      return filtered
    end

    local pattern = root .. '/configuration/**/configuration.json'
    local candidates = vim.fn.glob(pattern, false, true)
    local match_pattern = '"ref"%s*:%s*"' .. vim.pesc(ref_name) .. '"'
    local found = {}

    for _, path in ipairs(candidates) do
      local lines = read_lines(path)
      for _, line in ipairs(lines) do
        if line:match(match_pattern) then
          table.insert(found, path)
          break
        end
      end
    end

    M._cache.ref_callers[caller_key] = dedupe(found, true)

    local filtered = {}
    for _, path in ipairs(M._cache.ref_callers[caller_key]) do
      if path ~= current_config then
        table.insert(filtered, path)
      end
    end
    return filtered
  end

  local visited_configs = {}

  local function collect(config_file, source_file, depth, prefer_prefix)
    if not config_file or config_file == '' or visited_configs[config_file] then
      return
    end
    visited_configs[config_file] = true

    add_local_candidates(config_file, source_file)

    if not include_callers or depth >= max_depth then
      return
    end

    local sinkgroup_name = sinkgroup_name_from_config(config_file)
    if not sinkgroup_name then
      return
    end

    local callers = scan_ref_callers(sinkgroup_name, workspace_root(config_file), config_file)
    table.sort(callers, function(a, b)
      local sa = shared_prefix_len(a, prefer_prefix or dirname(config_file))
      local sb = shared_prefix_len(b, prefer_prefix or dirname(config_file))
      if sa ~= sb then
        return sa > sb
      end
      return a < b
    end)

    for idx, caller in ipairs(callers) do
      if idx > max_configs then
        break
      end
      collect(caller, nil, depth + 1, prefer_prefix or dirname(config_file))
    end
  end

  collect(config_path, current_file, 0, dirname(config_path))

  local result = dedupe(out, true)
  M._cache.schema_candidates[cache_key] = vim.deepcopy(result)
  return result
end

local function input_scan_files_for(config_path, current_file)
  local owner_dir = dirname(config_path)
  local artifacts = M._opts.input_props_scan_artifacts or { 'mapping.js', 'apply.js' }
  local out = {}

  for _, artifact in ipairs(artifacts) do
    local pattern = owner_dir .. '/sinkMappings/*/' .. artifact
    local matches = vim.fn.glob(pattern, false, true)
    for _, path in ipairs(matches) do
      table.insert(out, path)
    end
  end

  if current_file:match '/mapping%.js$' or current_file:match '/apply%.js$' then
    table.insert(out, current_file)
  end

  return dedupe(out, true)
end

local function parse_exported_params(lines)
  local chunk = table.concat(lines or {}, ' ')

  local raw = chunk:match 'module%.exports%s*=%s*function%s*[%w_]*%s*%(([^)]*)%)'
  if not raw then
    raw = chunk:match 'module%.exports%s*=%s*%(([^)]*)%)%s*=>'
  end

  if not raw then
    return {}
  end

  local out = {}
  for token in raw:gmatch '[^,]+' do
    local cleaned = vim.trim(token)
    cleaned = cleaned:gsub('=.*$', '')
    cleaned = vim.trim(cleaned)
    if cleaned ~= '' then
      table.insert(out, cleaned)
    end
  end

  return out
end

local function input_param_names(file, lines)
  local params = parse_exported_params(lines)
  local basename = vim.fn.fnamemodify(file, ':t')
  local set = {}

  local function add(name)
    if type(name) == 'string' and name ~= '' then
      set[name] = true
    end
  end

  if basename == 'mapping.js' and params[1] then
    add(params[1])
  end

  if basename == 'apply.js' and params[2] then
    add(params[2])
  end

  for _, name in ipairs(params) do
    if name:lower():find('input', 1, true) then
      add(name)
    end
  end

  if next(set) == nil then
    add 'input'
    add 'sinkInput'
  end

  return sorted_keys(set)
end

local input_chain_stop_words = {
  map = true,
  filter = true,
  reduce = true,
  find = true,
  findIndex = true,
  forEach = true,
  some = true,
  every = true,
  includes = true,
  sort = true,
  slice = true,
  splice = true,
  concat = true,
  flatMap = true,
  join = true,
  push = true,
  pop = true,
  shift = true,
  unshift = true,
  length = true,
}

local function normalize_chain_parts(chain)
  if not chain or chain == '' then
    return nil
  end

  local parts = {}

  for token in tostring(chain):gmatch '[%w_]+' do
    if token ~= '' then
      if input_chain_stop_words[token] then
        break
      end
      if token:match '^%d+$' then
        break
      end
      table.insert(parts, token)
    end
  end

  if #parts == 0 then
    return nil
  end

  return parts
end

local function append_path_segments(counter, parts)
  local current = ''

  for _, part in ipairs(parts or {}) do
    current = current == '' and part or (current .. '.' .. part)
    counter[current] = (counter[current] or 0) + 1
  end
end

local function collect_observed_input_props(scan_files)
  local out = {}

  for _, path in ipairs(scan_files or {}) do
    local lines = read_lines(path)
    if #lines > 0 then
      local names = input_param_names(path, lines)

      for _, line in ipairs(lines) do
        local normalized = line:gsub('%?%.', '.')
        normalized = normalized:gsub("%[['\"]([%w_]+)['\"]%]", '.%1')

        for _, name in ipairs(names) do
          local var = '%f[%w_]' .. vim.pesc(name) .. '%f[^%w_]'

          for chain in normalized:gmatch(var .. '%.([%w_%.]+)') do
            local parts = normalize_chain_parts(chain)
            if parts then
              append_path_segments(out, parts)
            end
          end
        end
      end
    end
  end

  return out
end

local function schema_type_label(node)
  if type(node) ~= 'table' then
    return 'any'
  end

  local schema_type = node.type
  if type(schema_type) == 'string' and schema_type ~= '' then
    return schema_type
  end

  if type(schema_type) == 'table' and #schema_type > 0 then
    return table.concat(schema_type, '|')
  end

  if type(node.properties) == 'table' then
    return 'object'
  end

  if type(node.items) == 'table' then
    return 'array'
  end

  if type(node.enum) == 'table' then
    return 'enum'
  end

  return 'any'
end

local function component_ref_name(ref)
  if type(ref) ~= 'string' then
    return nil
  end

  return ref:match '^component:([^#]+)'
end

local function resolve_component_schema(component_name, root, prefer_dir, cache)
  cache.components = cache.components or {}
  local cached = cache.components[component_name]

  if cached == false then
    return nil, nil
  end

  if cached then
    return cached.data, cached.path
  end

  local pattern = root .. '/configuration/**/component/' .. component_name .. '/dataSchema.json'
  local matches = vim.fn.glob(pattern, false, true)
  local selected = best_path_match(matches, prefer_dir)

  if not selected then
    cache.components[component_name] = false
    return nil, nil
  end

  local data = decode_json_file(selected)
  if not data then
    cache.components[component_name] = false
    return nil, nil
  end

  cache.components[component_name] = {
    data = data,
    path = selected,
  }

  return data, selected
end

local function flatten_schema_props(node, prefix, state, out)
  if type(node) ~= 'table' then
    return
  end

  local ref = node['$ref']
  if type(ref) == 'string' then
    local component_name = component_ref_name(ref)
    if component_name then
      local resolved, path = resolve_component_schema(component_name, state.root, state.prefer_dir, state.cache)
      if resolved and path then
        local guard = path .. '|' .. prefix
        if not state.visited[guard] then
          state.visited[guard] = true
          flatten_schema_props(resolved, prefix, {
            root = state.root,
            prefer_dir = dirname(path),
            cache = state.cache,
            visited = state.visited,
            unresolved = state.unresolved,
          }, out)
        end
      else
        state.unresolved[component_name] = true
      end
    end
  end

  for _, key in ipairs { 'allOf', 'anyOf', 'oneOf' } do
    local branch = node[key]
    if type(branch) == 'table' then
      for _, item in ipairs(branch) do
        flatten_schema_props(item, prefix, state, out)
      end
    end
  end

  local props = node.properties
  if type(props) == 'table' then
    local required_set = {}
    for _, req_name in ipairs(node.required or {}) do
      required_set[req_name] = true
    end

    for name, child in pairs(props) do
      local path = prefix ~= '' and (prefix .. '.' .. name) or name
      local existing = out[path]
      local required = required_set[name] or false

      if not existing then
        out[path] = {
          type = schema_type_label(child),
          required = required,
        }
      elseif required then
        existing.required = true
      end

      flatten_schema_props(child, path, state, out)
    end
  end

  local items = node.items
  if type(items) == 'table' then
    local path = prefix ~= '' and (prefix .. '[]') or '[]'
    if not out[path] then
      out[path] = {
        type = schema_type_label(items),
        required = false,
      }
    end

    flatten_schema_props(items, path, state, out)
  end
end

local function collect_schema_props(schema_files, root)
  local out = {}
  local unresolved = {}
  local cache = {
    components = {},
  }

  for _, path in ipairs(schema_files or {}) do
    local data = decode_json_file(path)
    if data then
      flatten_schema_props(data, '', {
        root = root,
        prefer_dir = dirname(path),
        cache = cache,
        visited = {},
        unresolved = unresolved,
      }, out)
    end
  end

  return out, unresolved
end

local function normalized_schema_path(path)
  return tostring(path or ''):gsub('%[%]', '')
end

local function used_input_path_set(observed_props)
  local out = {}

  for path in pairs(observed_props or {}) do
    local current = normalized_schema_path(path)

    while current and current ~= '' do
      out[current] = true
      current = current:match '^(.*)%.'
    end
  end

  return out
end

local function filter_schema_props_by_used(schema_props, observed_props)
  local used = used_input_path_set(observed_props)
  if next(used) == nil then
    return {}
  end

  local out = {}

  for path, meta in pairs(schema_props or {}) do
    if used[normalized_schema_path(path)] then
      out[path] = meta
    end
  end

  return out
end

local function build_input_props_lines(config_path, schema_files, schema_props, unresolved_refs, observed_props, root)
  local lines = {
    'Config: ' .. to_relative(config_path, root),
    '',
    'Schema files:',
  }

  if #schema_files == 0 then
    table.insert(lines, '- none near current config')
  else
    for _, path in ipairs(schema_files) do
      table.insert(lines, '- ' .. to_relative(path, root))
    end
  end

  table.insert(lines, '')
  table.insert(lines, 'Input schema properties:')

  local schema_keys = sorted_keys(schema_props)
  local limit = tonumber(M._opts.input_props_limit) or 300

  if #schema_keys == 0 then
    table.insert(lines, '- none (no resolved schema properties)')
  else
    for idx, key in ipairs(schema_keys) do
      if idx > limit then
        table.insert(lines, string.format('- ... truncated (%d total)', #schema_keys))
        break
      end

      local meta = schema_props[key] or {}
      local req = meta.required and ', required' or ''
      table.insert(lines, string.format('- %s (%s%s)', key, meta.type or 'any', req))
    end
  end

  local unresolved = sorted_keys(unresolved_refs)
  if #unresolved > 0 then
    table.insert(lines, '')
    table.insert(lines, 'Unresolved component refs:')
    for _, name in ipairs(unresolved) do
      table.insert(lines, '- component:' .. name)
    end
  end

  table.insert(lines, '')
  table.insert(lines, 'Observed input/sinkInput props in code:')

  local observed_keys = sorted_keys(observed_props)
  if #observed_keys == 0 then
    table.insert(lines, '- none')
  else
    for _, key in ipairs(observed_keys) do
      table.insert(lines, string.format('- %s (%d)', key, observed_props[key]))
    end
  end

  return lines
end

local function is_mapping_or_apply_file(path)
  return type(path) == 'string' and (path:match '/mapping%.js$' or path:match '/apply%.js$')
end

local function to_jsdoc_type(schema_type)
  if not schema_type or schema_type == '' then
    return '*'
  end

  local map = {
    string = 'string',
    integer = 'number',
    number = 'number',
    boolean = 'boolean',
    object = 'Object',
    array = 'Array',
    null = 'null',
    any = '*',
    enum = '*',
  }

  local set = {}
  local items = {}

  for raw in tostring(schema_type):gmatch '[^|]+' do
    local key = vim.trim(raw)
    local js_type = map[key] or (key ~= '' and key or '*')
    if not set[js_type] then
      set[js_type] = true
      table.insert(items, js_type)
    end
  end

  if #items == 0 then
    return '*'
  end

  if #items == 1 then
    return items[1]
  end

  table.sort(items)
  return '(' .. table.concat(items, '|') .. ')'
end

local function sanitize_identifier(value)
  local cleaned = tostring(value or ''):gsub('[^%w_]', '_')
  cleaned = cleaned:gsub('_+', '_')
  if cleaned == '' then
    cleaned = 'Input'
  end
  if cleaned:match '^[0-9]' then
    cleaned = '_' .. cleaned
  end
  return cleaned
end

local function typedef_name_for(path, config_path)
  local owner = dirname(config_path):match '/([^/]+)$' or 'Config'
  local step = path:match '/sinkMappings/([^/]+)/' or vim.fn.fnamemodify(path, ':t:r')
  return 'AdinsureInput_' .. sanitize_identifier(owner .. '_' .. step)
end

local function loaded_bufnr_for_path(path)
  local bufnr = vim.fn.bufnr(path)
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    return bufnr
  end
  return nil
end

local function read_lines_for_path(path)
  local bufnr = loaded_bufnr_for_path(path)
  if bufnr then
    return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), bufnr
  end
  return read_lines(path), nil
end

local function write_lines_for_path(path, lines)
  local bufnr = loaded_bufnr_for_path(path)
  if bufnr then
    local ok, err = pcall(vim.api.nvim_buf_set_lines, bufnr, 0, -1, false, lines)
    if not ok then
      return false, tostring(err)
    end
    return true, 'buffer'
  end

  local ok, err = pcall(vim.fn.writefile, lines, path)
  if not ok then
    return false, tostring(err)
  end
  return true, 'file'
end

local function strip_generated_jsdoc(lines)
  local out = {}
  local marker = M._opts.jsdoc_marker or '@adinsure-generated input-types'
  local idx = 1

  while idx <= #lines do
    if lines[idx]:match '^%s*/%*%*' then
      local j = idx
      local has_marker = false
      local has_generated_typedef = false
      local closed = false

      while j <= #lines do
        if lines[j]:find(marker, 1, true) then
          has_marker = true
        end
        if lines[j]:match '@typedef%s+{[^}]+}%s+AdinsureInput_' then
          has_generated_typedef = true
        end
        if lines[j]:find '%*/' then
          closed = true
          break
        end
        j = j + 1
      end

      if closed and (has_marker or has_generated_typedef) then
        idx = j + 1
        if lines[idx] == '' then
          idx = idx + 1
        end
      else
        table.insert(out, lines[idx])
        idx = idx + 1
      end
    else
      table.insert(out, lines[idx])
      idx = idx + 1
    end
  end

  return out
end

local function insert_jsdoc_block(lines, block)
  local clean = strip_generated_jsdoc(lines)
  local insert_at = nil

  for idx, line in ipairs(clean) do
    if line:match 'module%.exports%s*=' then
      insert_at = idx
      break
    end
  end

  if not insert_at then
    insert_at = 1
  end

  local out = {}
  for i = 1, insert_at - 1 do
    table.insert(out, clean[i])
  end

  for _, line in ipairs(block) do
    table.insert(out, line)
  end

  for i = insert_at, #clean do
    table.insert(out, clean[i])
  end

  return out
end

local function jsdoc_target_files(config_path, ctx, all_targets)
  if all_targets then
    return input_scan_files_for(config_path, '')
  end

  if is_mapping_or_apply_file(ctx.file) then
    return { ctx.file }
  end

  if ctx.file:match '/configuration%.json$' then
    local step = line_value(ctx.line, 'name')
    if step then
      return step_artifacts_for(ctx.file, step, M._opts.input_props_scan_artifacts or { 'mapping.js', 'apply.js' })
    end
  end

  return {}
end

local function input_param_name_for(path, params)
  local basename = vim.fn.fnamemodify(path, ':t')
  if basename == 'mapping.js' then
    return params[1]
  end
  if basename == 'apply.js' then
    return params[2] or params[1]
  end

  for _, p in ipairs(params) do
    if p:lower():find('input', 1, true) then
      return p
    end
  end

  return params[1]
end

local function default_param_type(param_name)
  local lowered = (param_name or ''):lower()
  if lowered:find('input', 1, true) then
    return '*'
  end
  if lowered:find('result', 1, true) then
    return 'Object'
  end
  if lowered:find('exchange', 1, true) or lowered:find('context', 1, true) then
    return 'Object'
  end
  if lowered:find('source', 1, true) or lowered:find('provider', 1, true) then
    return 'Object'
  end
  return '*'
end

local function normalized_schema_index(schema_props)
  local out = {}

  for path in pairs(schema_props or {}) do
    out[normalized_schema_path(path)] = true
  end

  return out
end

local function build_jsdoc_block(path, config_path, root, jsdoc_mode)
  local lines = read_lines_for_path(path)
  if #lines == 0 then
    return nil, 'empty file'
  end

  local params = parse_exported_params(lines)
  if #params == 0 then
    return nil, 'module.exports signature not found'
  end

  local schema_files = schema_candidates_for(config_path, path)
  local all_schema_props, unresolved_refs = collect_schema_props(schema_files, root)
  local observed_props = collect_observed_input_props { path }
  local props_mode = tostring(jsdoc_mode or M._opts.jsdoc_props_mode or 'all'):lower()

  local schema_props = all_schema_props
  if props_mode == 'used' then
    schema_props = filter_schema_props_by_used(all_schema_props, observed_props)
  end

  local typedef_name = typedef_name_for(path, config_path)
  local prop_limit = tonumber(M._opts.jsdoc_prop_limit) or 250
  local include_observed = not not M._opts.jsdoc_include_observed
  local schema_index = normalized_schema_index(schema_props)

  local props = {}
  local prop_names = sorted_keys(schema_props)
  for _, name in ipairs(prop_names) do
    local meta = schema_props[name] or {}
    table.insert(props, {
      name = name,
      type = to_jsdoc_type(meta.type),
      required = not not meta.required,
      source = 'schema',
      observed = observed_props[name],
    })
  end

  if include_observed then
    for name, count in pairs(observed_props) do
      if not schema_index[normalized_schema_path(name)] then
        table.insert(props, {
          name = name,
          type = '*',
          required = false,
          source = 'observed',
          observed = count,
        })
      end
    end
  end

  table.sort(props, function(a, b)
    return a.name < b.name
  end)

  local input_param = input_param_name_for(path, params) or 'input'
  local block = {
    '/**',
    ' * @typedef {Object} ' .. typedef_name,
  }

  for idx, entry in ipairs(props) do
    if idx > prop_limit then
      table.insert(block, string.format(' * @property {*} __truncated__ - %d total properties', #props))
      break
    end

    local suffix = ''
    if not entry.required then
      suffix = ' - optional'
    end
    if entry.source == 'observed' then
      suffix = string.format(' - observed in code (%d)', entry.observed or 1)
    end

    table.insert(block, string.format(' * @property {%s} %s%s', entry.type, entry.name, suffix))
  end

  if #props > 0 then
    table.insert(block, ' *')
  end

  local unresolved_names = sorted_keys(unresolved_refs)
  if #unresolved_names > 0 then
    table.insert(block, ' *')
    table.insert(block, ' * Unresolved refs:')
    for _, name in ipairs(unresolved_names) do
      table.insert(block, ' * - component:' .. name)
    end
    table.insert(block, ' *')
  end

  for _, param_name in ipairs(params) do
    local js_type = default_param_type(param_name)
    if param_name == input_param then
      js_type = typedef_name
    end
    table.insert(block, string.format(' * @param {%s} %s', js_type, param_name))
  end

  table.insert(block, ' * @returns {*}')
  table.insert(block, ' */')
  table.insert(block, '')

  return block, {
    typedef = typedef_name,
    schema_files = schema_files,
    property_count = #props,
  }
end

local function apply_jsdoc_to_file(path, config_path, root, jsdoc_mode)
  if not is_mapping_or_apply_file(path) then
    return false, 'not mapping/apply file'
  end

  local source_lines = read_lines_for_path(path)
  if #source_lines == 0 then
    return false, 'empty file'
  end

  local block, err = build_jsdoc_block(path, config_path, root, jsdoc_mode)
  if not block then
    return false, err
  end

  local updated_lines = insert_jsdoc_block(source_lines, block)
  local ok, write_err = write_lines_for_path(path, updated_lines)
  if not ok then
    return false, write_err
  end

  return true
end

local function add_default_resolvers()
  M.register_resolver('local_ref_step_artifacts', function(ctx)
    if not ctx.file:match '/configuration%.json$' then
      return nil
    end

    local ref_name = line_value(ctx.line, 'ref')
    if not ref_name then
      return nil
    end

    local preferred = step_artifacts_for(ctx.file, ref_name, { 'mapping.js' })
    if #preferred > 0 then
      return {
        prompt = 'AdInsure step(ref): ' .. ref_name,
        paths = preferred,
      }
    end

    local targets = step_artifacts_for(ctx.file, ref_name, M._opts.step_artifacts)
    if #targets == 0 then
      return nil
    end

    return {
      prompt = 'AdInsure step(ref): ' .. ref_name,
      paths = targets,
    }
  end)

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

function M.show_flow()
  if not M._ready then
    M.setup()
  end

  local ctx = build_context()
  local config_path = owner_configuration_file(ctx.file)

  if not config_path or not path_exists(config_path) then
    vim.notify('AdInsureFlow: open configuration.json or sinkMappings/* first', vim.log.levels.WARN)
    return false
  end

  local records, unresolved = collect_sinkgroup_flow(config_path, ctx.root)
  local entries = {}

  for _, record in ipairs(records) do
    if record.path and path_exists(record.path) then
      table.insert(entries, {
        path = record.path,
        label = flow_record_label(record, ctx.root),
        ordinal = string.format('%04d %s %s', record.step_index or 0, record.ref or '', record.path),
      })
    end
  end

  if #entries == 0 then
    vim.notify('AdInsureFlow: no sinkGroup refs found', vim.log.levels.INFO)
    return false
  end

  if unresolved > 0 then
    vim.notify(string.format('AdInsureFlow: %d unresolved sinkGroup ref(s)', unresolved), vim.log.levels.INFO)
  end

  return pick_records_or_open(entries, 'AdInsure flow: sinkGroups')
end

function M.context_trace(opts)
  opts = opts or {}

  if not M._ready then
    M.setup()
  end

  local ctx = build_context()
  local config_path = owner_configuration_file(ctx.file)

  if not config_path or not path_exists(config_path) then
    vim.notify('AdinsureContextTrace: open configuration.json or sinkMappings/* first', vim.log.levels.WARN)
    return false
  end

  local steps = extract_sink_steps(config_path)
  if #steps == 0 then
    vim.notify('AdinsureContextTrace: no sinks found in current configuration', vim.log.levels.INFO)
    return false
  end

  local signals = collect_context_signals(config_path, steps)
  local key = opts.key

  if (not key or key == '') and M._opts.context_trace_auto_key then
    local cword = ctx.cword
    if cword and cword:match '^[%a_][%w_]*$' then
      key = cword
    end
  end

  if key and key ~= '' then
    local matches = {}

    for _, signal in ipairs(signals) do
      if signal.key == key then
        table.insert(matches, signal)
      end
    end

    if #matches > 0 then
      local items = {}

      for _, signal in ipairs(matches) do
        table.insert(items, {
          filename = signal.file,
          lnum = signal.lnum,
          col = 1,
          text = string.format('[%02d:%s][%s][%s] %s', signal.step_index, signal.step, signal.artifact, signal.mode, signal.text),
        })
      end

      vim.fn.setqflist({}, ' ', {
        title = 'AdInsure ContextTrace: ' .. key,
        items = items,
      })
      vim.cmd 'copen'
      return true
    end
  end

  local lines = build_context_summary_lines(config_path, steps, signals, ctx.root)
  open_full_width_scratch(lines, 'AdInsure ContextTrace')

  if key and key ~= '' then
    vim.notify(string.format('AdinsureContextTrace: key "%s" not found, opened summary', key), vim.log.levels.INFO)
  end

  return true
end

function M.input_props()
  if not M._ready then
    M.setup()
  end

  local ctx = build_context()
  local config_path = owner_configuration_file(ctx.file)

  if not config_path or not path_exists(config_path) then
    vim.notify('AdinsureInputProps: open configuration.json or sinkMappings/* first', vim.log.levels.WARN)
    return false
  end

  local schema_files = schema_candidates_for(config_path, ctx.file)
  local schema_props, unresolved_refs = collect_schema_props(schema_files, ctx.root)

  local scan_files = input_scan_files_for(config_path, ctx.file)
  local observed_props = collect_observed_input_props(scan_files)

  local lines = build_input_props_lines(config_path, schema_files, schema_props, unresolved_refs, observed_props, ctx.root)
  open_full_width_scratch(lines, 'AdInsure Input Props')
  return true
end

function M.insert_jsdoc(opts)
  opts = opts or {}

  if not M._ready then
    M.setup()
  end

  local ctx = build_context()
  local config_path = owner_configuration_file(ctx.file)

  if not config_path or not path_exists(config_path) then
    vim.notify('AdinsureInsertJSDoc: open configuration.json or sinkMappings/* first', vim.log.levels.WARN)
    return false
  end

  local targets = jsdoc_target_files(config_path, ctx, opts.all == true)
  targets = dedupe(targets, true)
  local mode = opts.mode

  if #targets == 0 then
    vim.notify('AdinsureInsertJSDoc: no mapping/apply target found', vim.log.levels.INFO)
    return false
  end

  local updated = 0
  local failed = {}

  for _, path in ipairs(targets) do
    local ok, err = apply_jsdoc_to_file(path, config_path, ctx.root, mode)
    if ok then
      updated = updated + 1
    else
      table.insert(failed, {
        path = path,
        err = err or 'unknown error',
      })
    end
  end

  if #failed > 0 then
    local items = {}
    for _, item in ipairs(failed) do
      table.insert(items, {
        filename = item.path,
        lnum = 1,
        col = 1,
        text = 'JSDoc generation failed: ' .. item.err,
      })
    end

    vim.fn.setqflist({}, ' ', {
      title = 'AdInsure JSDoc generation failures',
      items = items,
    })
    vim.cmd 'copen'
  end

  vim.notify(
    string.format('Adinsure JSDoc: updated %d file(s), failed %d', updated, #failed),
    (#failed > 0 and vim.log.levels.WARN or vim.log.levels.INFO)
  )

  return updated > 0
end

function M.setup(opts)
  if M._ready then
    return M
  end

  M._cache = {
    schema_candidates = {},
    ref_callers = {},
  }

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

  vim.api.nvim_create_user_command('AdinsureFlow', function()
    M.show_flow()
  end, { desc = 'AdInsure sinkGroup flow' })

  vim.api.nvim_create_user_command('AdinsureContextTrace', function(command_opts)
    local key = command_opts.args ~= '' and command_opts.args or nil
    M.context_trace { key = key }
  end, {
    desc = 'AdInsure context trace (optional key)',
    nargs = '?',
  })

  vim.api.nvim_create_user_command('AdinsureInputProps', function()
    M.input_props()
  end, {
    desc = 'AdInsure input/sinkInput properties',
  })

  vim.api.nvim_create_user_command('AdinsureInsertJSDoc', function()
    M.insert_jsdoc { all = false }
  end, {
    desc = 'AdInsure generate JSDoc for current mapping/apply or step',
  })

  vim.api.nvim_create_user_command('AdinsureInsertJSDocPartial', function()
    M.insert_jsdoc {
      all = false,
      mode = 'used',
    }
  end, {
    desc = 'AdInsure generate partial (used-only) JSDoc for current mapping/apply or step',
  })

  vim.api.nvim_create_user_command('AdinsureGenerateJSDoc', function()
    M.insert_jsdoc { all = true }
  end, {
    desc = 'AdInsure generate JSDoc for all mapping/apply in current configuration',
  })

  M._ready = true
  return M
end

return M
