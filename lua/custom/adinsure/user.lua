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
