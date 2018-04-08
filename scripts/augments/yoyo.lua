require "/scripts/augments/item.lua"
require "/scripts/util.lua"

function apply(input)
  local output = Item.new(input)

  if output:instanceValue("currentStringType") == config.getParameter("itemName") then
    return nil
  end

  if not output:instanceValue("usesYoyoUpgrades") then
    return nil
  end

  local rope = output:instanceValue("rope").yoyo

  local defaults = {
    color = {255, 255, 255, 255},
    rainbow = false,
    hue = 0,
    hueRange = {0, 360},
    hueCycleSpeed = 1,
    lightColor = {}
  }

  rope = util.mergeTable(defaults, config.getParameter("rope"))

  output:setInstanceValue("currentStringType", config.getParameter("itemName"))
  --output:setInstanceValue("currentStringName", config.getParameter("shortdescription"))
  --output:setInstanceValue("currentStringIcon", config.getParameter("inventoryIcon"))
	output:setInstanceValue("rope", { yoyo = rope })
  output:setInstanceValue("stringColor", config.getParameter("stringColor"))
	output:setInstanceValue("extraLength", config.getParameter("extraLength"))

  return output:descriptor(), 1
end
