require "/scripts/augments/item.lua"

function apply(input)
  local output = Item.new(input)

  if not output:instanceValue("usesCounterweightUpgrades") then
    return nil
  end

  if output:instanceValue("counterWeightType") == config.getParameter("itemName") then
    return nil
  end

  local currentCounterweights = output:instanceValue("counterweights")

  for index,counterweight in pairs(currentCounterweights) do
    if counterweight.fromItem == true then
      currentCounterweights[index] = nil
    end
  end

  currentCounterweights = mergeTable(currentCounterweights, config.getParameter("counterweights"))

  output:setInstanceValue("counterWeightType", config.getParameter("itemName"))
  output:setInstanceValue("counterWeightName", config.getParameter("shortdescription"))
  output:setInstanceValue("counterWeightIcon", config.getParameter("inventoryIcon"))
  output:setInstanceValue("counterweights", currentCounterweights)

  return output:descriptor(), 1
end

function mergeTable(t1, t2)
  for k, v in pairs(t2) do
    if type(v) == "table" and type(t1[k]) == "table" then
      mergeTable(t1[k] or {}, v)
    else
      t1[k] = v
    end
  end
  return t1
end
