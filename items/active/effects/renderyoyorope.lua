require "/scripts/vec2.lua"

function update()
  localAnimator.clearDrawables()
  localAnimator.clearLightSources()

  for _,ropeId in pairs(animationConfig.animationParameter("ropes")) do
    params = animationConfig.animationParameter(ropeId .. "params")
    if params then
      local points = animationConfig.animationParameter(ropeId .. "points")

      local lastPoint = activeItemAnimation.handPosition(params.offset)
      if #points >= 2 then
        for i = 2,#points do
          local nextPoint = points[i]

          local position = activeItemAnimation.ownerPosition()
          local relativeNextPoint = world.distance(nextPoint, position)
          localAnimator.addDrawable({
            position = position,
            line = {lastPoint, relativeNextPoint},
            width = params.width,
            color = params.color,
            fullbright = params.fullbright
          }, "ForegroundTile+1")

          if params.lightColor and #params.lightColor > 0 then
            local segment = vec2.sub(relativeNextPoint, lastPoint)
            for i=1,20 do
              local ppos = vec2.add(vec2.add(position, lastPoint), vec2.mul(segment, math.random()))
              localAnimator.addLightSource({ position = ppos, color = params.lightColor })
            end
          end

          lastPoint = relativeNextPoint
        end
      end
    end
  end
end
