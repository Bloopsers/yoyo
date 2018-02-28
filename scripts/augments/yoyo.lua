require "/scripts/augments/item.lua"

function apply(input)
  local output = Item.new(input)

  if output:instanceValue("currentStringType") == config.getParameter("itemName") then
    return nil
  end

  if not output:instanceValue("usesYoyoUpgrades") then
    return nil
  end

  if output:instanceValue("currentStringType") then
    output:setInstanceValue("oldStringDescriptor", {name = output:instanceValue("currentStringType"), count = 1, parameters = {}})
  end

  local ropes = output:instanceValue("rope")

  for id,rope in pairs(ropes) do
    rope.color = config.getParameter("ropeColor")
  end

  output:setInstanceValue("currentStringType", config.getParameter("itemName"))
  --output:setInstanceValue("currentStringName", config.getParameter("shortdescription"))
  --output:setInstanceValue("currentStringIcon", config.getParameter("inventoryIcon"))
	output:setInstanceValue("shouldGiveString", true)
	output:setInstanceValue("rope", ropes)
  output:setInstanceValue("stringColor", config.getParameter("stringColor"))
	output:setInstanceValue("extraLength", config.getParameter("extraLength"))

  return output:descriptor(), 1
end
