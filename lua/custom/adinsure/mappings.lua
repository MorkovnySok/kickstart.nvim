local M = {}

M.kind_patterns = {
  sinkGroup = {
    'configuration/**/sinkGroup/%s/configuration.json',
  },
  dataSource = {
    'configuration/**/dataSource/%s/configuration.json',
  },
  dataProvider = {
    'configuration/**/dataProvider/%s/configuration.json',
    'configuration/**/dataProvider/**/%s/configuration.json',
  },
  document = {
    'configuration/**/document/%s/configuration.json',
  },
  documentRelation = {
    'configuration/**/documentRelation/%s/configuration.json',
  },
  masterEntity = {
    'configuration/**/masterEntity/%s/configuration.json',
  },
  etlService = {
    'configuration/**/etlService/%s/configuration.json',
  },
  integrationService = {
    'configuration/**/integrationService/%s/configuration.json',
  },
  messageChannelPolicy = {
    'configuration/**/messageChannelPolicy/%s/configuration.json',
  },
}

M.direct_key_to_kind = {
  ref = 'sinkGroup',
  policy = 'messageChannelPolicy',
  sourceDocument = 'document',
  targetDocument = 'document',
  configurationName = 'document',
  codeName = 'dataProvider',
}

M.context_key_to_kind = {
  fetch = 'dataSource',
  document = 'document',
  documentRelation = 'documentRelation',
  documentTransition = 'document',
  masterEntity = 'masterEntity',
  etlService = 'etlService',
  api = 'dataProvider',
  searchEngine = 'dataProvider',
  searchEngineDataProvider = 'dataProvider',
  messageChannel = 'messageChannelPolicy',
}

M.step_artifacts = {
  'mapping.js',
  'apply.js',
  'messageSchema.json',
  'inputSchema.json',
  'configuration.json',
}

M.use_telescope_picker = true

M.telescope_picker = {
  layout_strategy = 'horizontal',
  sorting_strategy = 'ascending',
  layout_config = {
    width = 0.99,
    height = 0.60,
    preview_width = 0.72,
    prompt_position = 'top',
  },
}

M.flow_max_depth = 12
M.flow_show_missing = true

M.context_variables = {
  'context',
  'ctx',
  'integrationContext',
}

M.context_trace_artifacts = {
  'mapping.js',
  'apply.js',
}

M.context_trace_auto_key = true

M.context_trace_window = {
  width = 0.99,
  height = 0.80,
  border = 'rounded',
}

M.input_props_schema_candidates = {
  'inputSchema.json',
  'messageSchema.json',
  'dataSchema.json',
}

M.input_props_include_callers = true
M.input_props_callers_max_depth = 3
M.input_props_callers_max_configs = 40

M.input_props_scan_artifacts = {
  'mapping.js',
  'apply.js',
}

M.input_props_limit = 300

M.jsdoc_marker = '@adinsure-generated input-types'
M.jsdoc_prop_limit = 250
M.jsdoc_include_observed = true
M.jsdoc_props_mode = 'all'

return M
