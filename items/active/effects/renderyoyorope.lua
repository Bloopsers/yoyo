require "/scripts/vec2.lua"

function update()
  localAnimator.clearDrawables()

  projectiles = animationConfig.animationParameter("projectiles", {})

  for index,projectile in pairs(projectiles) do
    if projectile.rope then
      if projectile.id and world.entityExists(projectile.id) then
        local handPosition = activeItemAnimation.handPosition({0, 0})
        local position = activeItemAnimation.ownerPosition()

        world.debugLine(handPosition, vec2.sub(world.entityPosition(projectile.id), position), "yellow")

        localAnimator.addDrawable({
          position = position,
          line = {handPosition, vec2.sub(world.entityPosition(projectile.id), position)},
          width = projectile.rope.width,
          color = projectile.rope.color,
          fullbright = projectile.rope.fullbright
        }, "ForegroundTile-1")
      end
    end
  end
end
