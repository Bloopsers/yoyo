require "/scripts/vec2.lua"

function init()
  mcontroller.applyParameters({gravityEnabled = false})
  self.controlMovement = config.getParameter("controlMovement")
  self.controlRotation = config.getParameter("controlRotation")
  self.rotationSpeed = 0
  self.ownerId = nil
  self.timedActions = config.getParameter("timedActions", {})
  self.leftClicking = false
  self.pickupDistance = config.getParameter("pickupDistance", 2)
  self.maxDistance = config.getParameter("maxDistance")
  self.yoyoTime = 0
  self.maxYoyoTime = config.getParameter("maxYoyoTime", 5)

  self.ownerId = projectile.sourceEntity()

  self.aimPosition = mcontroller.position()

  message.setHandler("updateProjectile", function(_, _, aimPosition)
    self.aimPosition = aimPosition
    return entity.id()
  end)

  message.setHandler("leftClicking", function(_, _, leftClicking)
    self.leftClicking = leftClicking
    return entity.id()
  end)
end

function kill()
  projectile.die()
end

function update(dt)
  self.yoyoTime = self.yoyoTime + (1 * dt)
  if self.yoyoTime >= self.maxYoyoTime then
    self.returning = true
    mcontroller.applyParameters({collisionEnabled = false})
  end

  if self.ownerId and world.entityExists(self.ownerId) then
    if self.aimPosition then
      if self.leftClicking == false or self.returning == true then
        controlTo(world.entityPosition(self.ownerId), 5)
        local toTarget = world.distance(world.entityPosition(self.ownerId), mcontroller.position())

        if vec2.mag(toTarget) < self.pickupDistance and self.yoyoTime > 0.15 then
          projectile.die()
        end
      else
        local toTarget = world.distance(self.aimPosition, mcontroller.position())
		    if vec2.mag(toTarget) < 0.5 then
          controlTo(self.aimPosition, 0)
        elseif vec2.mag(toTarget) < 2 then
		      controlTo(self.aimPosition, 0.1)
		    elseif vec2.mag(toTarget) < 4 then
		      controlTo(self.aimPosition, 0.3)
		    elseif vec2.mag(toTarget) < 6 then
		      controlTo(self.aimPosition, 0.45)
		    elseif vec2.mag(toTarget) < 8 then
		      controlTo(self.aimPosition, 0.575)
		    else
          controlTo(self.aimPosition, 1)
        end

        local distanceTraveled = world.magnitude(world.entityPosition(self.ownerId), mcontroller.position())

        if distanceTraveled > self.maxDistance then
          controlTo(world.entityPosition(self.ownerId), 2.5)
        end
      end
    end
  else
    projectile.die()
  end
  if self.returning == true then
	  mcontroller.setRotation(mcontroller.rotation() + (32 * dt))
  else
	  mcontroller.setRotation(mcontroller.rotation() - (32 * dt))
  end
end

function controlTo(position, speedModifier)
  speedModifier = speedModifier or 1
  local offset = world.distance(position, mcontroller.position())
  mcontroller.approachVelocity(vec2.mul(vec2.norm(offset), self.controlMovement.maxSpeed * speedModifier), self.controlMovement.controlForce * speedModifier)
end
