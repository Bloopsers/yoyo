require "/scripts/augments/item.lua"

function apply(input)
  local output = Item.new(input)

  if not output:instanceValue("usesYoyoUpgrades") then
    return nil
  end

  output:setInstanceValue("currentStringType", config.getParameter("itemName"))
  --output:setInstanceValue("currentStringName", config.getParameter("shortdescription"))
  --output:setInstanceValue("currentStringIcon", config.getParameter("inventoryIcon"))
	output:setInstanceValue("shouldGiveString", true)
	output:setInstanceValue("ropeColor", config.getParameter("ropeColor"))
  output:setInstanceValue("stringColor", config.getParameter("stringColor"))
	output:setInstanceValue("extraLength", config.getParameter("extraLength"))

  return output:descriptor(), 1
end
