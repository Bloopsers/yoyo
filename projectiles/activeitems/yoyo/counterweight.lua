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
  self.facingDirection = 1
  self.controlMovement = {
    maxSpeed = 50,
    controlForce = 120
  }

  rotateSpeed = 4
  if math.random(1, 2) == 1 then
    rotateSpeed = -4
  end
  angle = 0

  self.ownerId = projectile.sourceEntity()

  message.setHandler("facingDirection", function(_, _, facingDirection)
    self.facingDirection = facingDirection
    return entity.id()
  end)
end

function kill()
  projectile.die()
end

function update(dt)
  local ownerPos = world.entityPosition(self.ownerId)
  if mcontroller.isColliding() == true then
    rotateSpeed = rotateSpeed - rotateSpeed * 2
  end
  angle = angle + (rotateSpeed * dt)
  mcontroller.setRotation(angle)

  local radius = 7
  local offset = vec2.mul({math.sin(angle), math.cos(angle)}, radius)
  mcontroller.setPosition(world.nearestTo(ownerPos, vec2.add(ownerPos, offset)))
end
