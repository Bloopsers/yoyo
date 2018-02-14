require "/scripts/util.lua"

function build(directory, config, parameters, level, seed)
  local params = sb.jsonMerge(config, parameters)

  config.tooltipFields = {}
  config.tooltipFields.lengthLabel = string.format("%s (+%s)", params.maxLength, params.extraLength)

  local elementalType = params.elementalType or "physical"

  if elementalType ~= "physical" then
    config.tooltipFields.damageKindImage = "/interface/elements/"..elementalType..".png"
  end

  config.tooltipFields.counterWeightIconImage = parameters.counterWeightIcon or "/interface/tooltips/counterweightbase.png"
  config.tooltipFields.counterWeightNameLabel = parameters.counterWeightName or "^gray;No Counterweight"

  --config.tooltipFields.stringIconImage = params.currentStringIcon
  --config.tooltipFields.stringNameLabel = params.currentStringName

  parameters.inventoryIcon = config.inventoryIcon .. params.stringColor
  parameters.largeImage = config.largeImage .. params.stringColor

  return config, parameters
end
