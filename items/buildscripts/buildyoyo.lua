function build(directory, config, parameters, level, seed)
  config.tooltipFields = config.tooltipFields or {}

  config.tooltipFields.lengthLabel.value = tostring(parameters.maxLength)


  return config, parameters
end

function getRotTimeDescription(rotTime)
  local descList = root.assetJson("/items/rotting.config:rotTimeDescriptions")
  for i, desc in ipairs(descList) do
    if rotTime <= desc[1] then return desc[2] end
  end
  return descList[#descList]
end
