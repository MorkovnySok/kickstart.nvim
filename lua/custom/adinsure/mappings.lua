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

return M
