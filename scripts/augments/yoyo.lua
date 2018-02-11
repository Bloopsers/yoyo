require "/scripts/augments/item.lua"

function apply(input)
  local output = Item.new(input)

  if not output:instanceValue("usesYoyoUpgrades") then
    return nil
  end

    output:setInstanceValue("currentString", config.getParameter("itemName"))
	output:setInstanceValue("shouldGiveString", true)
	output:setInstanceValue("ropeColor", config.getParameter("ropeColor"))
	output:setInstanceValue("extraLength", config.getParameter("extraLength"))
	output:setInstanceValue("description", output:instanceValue("originalDescription") .. "\nLength: " .. output:instanceValue("maxLength") + output:instanceValue("extraLength"))
	output:setInstanceValue("inventoryIcon", output:instanceValue("originalInventoryIcon") .. "?replace;" .. config.getParameter("stringDirectives"))
	output:setInstanceValue("largeImage", output:instanceValue("originalLargeImage") .. "?replace;" .. config.getParameter("stringDirectives"))
    --output:setInstanceValue("stringParameters", config.getParameter("stringParameters"))
	--world.spawnItem(input:instanceValue("itemName"), world.entityPosition(entity.id()), 1)
	
    return output:descriptor(), 1
end
