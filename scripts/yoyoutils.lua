require "/scripts/vec2.lua"

yoyoUtils = {}

function yoyoUtils.circlePoly(radius, points, center)
	local poly = {}
	center = center or {0, 0}
	for i = 0, points - 1 do
		local angle = (i / points) * math.pi * 2
		table.insert(poly, vec2.add(center, vec2.withAngle(angle, radius)))
	end
	return poly
end

function yoyoUtils.length(vector)
	return math.sqrt(vec2.dot(vector, vector))
end
  
function yoyoUtils.clampMag(vector, maxLength)
	if yoyoUtils.length(vector) > maxLength then
		vector = vec2.norm(vector)
		vector = vec2.mul(vector, maxLength)
	end
	return vector
end

function yoyoUtils.hslToRgb(h, s, l, a)
    if s <= 0 then return {l, l, l, 255} end
    h, s, l = h / 360 * 6, s / 255, l / 255
    local c = (1 - math.abs(2 * l - 1)) * s
    local x = (1 - math.abs(h % 2 - 1)) * c
    local m, r, g, b = (l - .5 * c), 0, 0, 0
    if h < 1 then
        r, g, b = c, x, 0
    elseif h < 2 then
        r, g, b = x, c, 0
    elseif h < 3 then
        r, g, b = 0, c, x
    elseif h < 4 then
        r, g, b = 0, x, c
    elseif h < 5 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    return {(r + m) * 255, (g + m) * 255, (b + m) * 255, a}
end