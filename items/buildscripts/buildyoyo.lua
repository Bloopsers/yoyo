require "/scripts/util.lua"

function build(directory, config, parameters, level, seed)
  local params = sb.jsonMerge(config, parameters)

  config.tooltipFields = {}

  local power = params.projectileParameters.power * root.evalFunction("weaponDamageLevelMultiplier", params.level)
  local dps = round(power / params.projectileParameters.damageRepeatTimeout * 1, 1)
  config.tooltipFields.damageLabel = dps

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

function round(num, numDecimalPlaces)
  if numDecimalPlaces and numDecimalPlaces>0 then
    local mult = 10^numDecimalPlaces
    return math.floor(num * mult + 0.5) / mult
  end
  return math.floor(num + 0.5)
end
