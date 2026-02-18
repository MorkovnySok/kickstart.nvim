-- AdInsure navigation customizations.
-- This file is loaded automatically by `custom.adinsure`.

return {
  -- Optional UI tuning for multi-target picker.
  -- use_telescope_picker = true,
  -- telescope_picker = {
  --   layout_strategy = 'horizontal',
  --   layout_config = {
  --     width = 0.99,
  --     height = 0.70,
  --     preview_width = 0.75,
  --     prompt_position = 'top',
  --   },
  -- },

  -- Optional: tune sinkGroup flow recursion and unresolved refs visibility.
  -- flow_max_depth = 16,
  -- flow_show_missing = true,

  -- Optional: tune ContextTrace behavior.
  -- context_variables = { 'context', 'ctx', 'integrationContext' },
  -- context_trace_artifacts = { 'mapping.js', 'apply.js' },
  -- context_trace_auto_key = true,
  -- context_trace_window = {
  --   width = 0.99,
  --   height = 0.85,
  --   border = 'single',
  -- },
  --
  -- Optional: tune input/sinkInput hints.
  -- input_props_schema_candidates = { 'inputSchema.json', 'messageSchema.json', 'dataSchema.json' },
  -- input_props_include_callers = true,
  -- input_props_callers_max_depth = 3,
  -- input_props_callers_max_configs = 40,
  -- input_props_scan_artifacts = { 'mapping.js', 'apply.js' },
  -- input_props_limit = 400,
  --
  -- Optional: tune JSDoc generation.
  -- jsdoc_marker = '@adinsure-generated input-types',
  -- jsdoc_prop_limit = 300,
  -- jsdoc_include_observed = true,
  -- jsdoc_props_mode = 'all', -- 'used' | 'all'

  -- Example: register additional kinds and resolvers after core setup.
  on_setup = function(nav)
    -- nav.register_kind('printout', {
    --   'configuration/**/printout/%s/configuration.json',
    -- })
    --
    -- nav.register_resolver('printout_name_key', function(ctx)
    --   local name = ctx.line:match('"printoutName"%s*:%s*"([^"]+)"')
    --   if not name then
    --     return nil
    --   end
    --
    --   return {
    --     prompt = 'AdInsure printout: ' .. name,
    --     paths = vim.fn.glob(ctx.root .. '/configuration/**/printout/' .. name .. '/configuration.json', false, true),
    --   }
    -- end)
  end,
}
