require "/scripts/augments/item.lua"
require "/scripts/util.lua"

function apply(input)
	local output = Item.new(input)

	if output:instanceValue("currentStringType") == config.getParameter("itemName") then return nil end

	if not output:instanceValue("usesYoyoUpgrades") then return nil end

	local defaults = {
		color = {255, 255, 255, 255},
		rainbow = false,
		hue = 0,
		hueRange = {0, 360},
		hueCycleSpeed = 1,
		fullbright = false
	}
	local rope = sb.jsonMerge(defaults, config.getParameter("rope"))

	output:setInstanceValue("currentStringType", config.getParameter("itemName"))
	output:setInstanceValue("rope", rope)
	output:setInstanceValue("stringColor", config.getParameter("stringColor"))
	output:setInstanceValue("extraLength", config.getParameter("extraLength"))

	return output:descriptor(), 1
end
