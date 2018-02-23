require "/scripts/vec2.lua"

function init()
  mcontroller.applyParameters({gravityEnabled = false})

  self.rotationSpeed = config.getParameter("rotationSpeed", 25)
  self.ownerId = nil
  self.timedActions = config.getParameter("timedActions", {})
  self.leftClicking = true
  self.pickupDistance = config.getParameter("pickupDistance", 2)
  self.maxDistance = config.getParameter("maxDistance")
  self.yoyoTime = 0
  self.maxYoyoTime = config.getParameter("maxYoyoTime", 5)
  self.yoyoSpeed = config.getParameter("yoyoSpeed", 32)

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

function circle(radius, points, center)
  local poly = {}
  center = center or {0, 0}
  for i = 0, points - 1 do
    local angle = (i / points) * math.pi * 2
    table.insert(poly, vec2.add(center, vec2.withAngle(angle, radius)))
  end
  return poly
end

function update(dt)
  world.debugPoly(circle(self.maxDistance, 32, world.entityPosition(self.ownerId)), {0, 255, 0})

  self.yoyoTime = self.yoyoTime + (1 * dt)

  if self.yoyoTime >= self.maxYoyoTime then
    self.returning = true
    mcontroller.applyParameters({collisionEnabled = false})
  end

  if self.leftClicking == false then
    self.returning = true
  end

  if self.ownerId and world.entityExists(self.ownerId) then
    if self.aimPosition then
      if self.yoyoTime > 0.15 and self.returning == true then
        controlTo(world.entityPosition(self.ownerId), self.yoyoSpeed * 1.5)
        local toTarget = world.distance(world.entityPosition(self.ownerId), mcontroller.position())

        if vec2.mag(toTarget) < self.pickupDistance and self.yoyoTime > 0.15 then
          projectile.die()
        end
      else
        local distToPos = world.magnitude(mcontroller.position(), self.aimPosition)

        if world.magnitude(world.entityPosition(self.ownerId), mcontroller.position()) > self.maxDistance then
          controlTo(self.aimPosition, self.yoyoSpeed, self.maxDistance, world.entityPosition(self.ownerId))
        elseif distToPos < 0.3 then
          controlTo(self.aimPosition, 0)
        elseif distToPos < 0.5 then
          controlTo(self.aimPosition, self.yoyoSpeed / 3)
        elseif distToPos < 0.9 then
          controlTo(self.aimPosition, self.yoyoSpeed / 2.2)
        elseif distToPos < 1.3 then
          controlTo(self.aimPosition, self.yoyoSpeed / 1.4)
        else
          controlTo(self.aimPosition, self.yoyoSpeed)
        end
      end
    end
  else
    projectile.die()
  end

  if self.returning == true then
	  mcontroller.setRotation(mcontroller.rotation() + (self.rotationSpeed * dt))
  else
	  mcontroller.setRotation(mcontroller.rotation() - (self.rotationSpeed * dt))
  end
end

function controlTo(position, speed, radius, radiusCenter)
  local speed = speed or self.yoyoSpeed
  local offset = world.distance(position, mcontroller.position())
  local vel = vec2.mul(vec2.norm(offset), speed)
  if radius then
    local distance = world.magnitude(mcontroller.position(), radiusCenter)
    if distance > radius and distance < radius +1 then
      local fromOriginToPoint = vec2.sub(radiusCenter, mcontroller.position())
      fromOriginToPoint = vec2.mul(fromOriginToPoint, radius / distance)
      local newLocation = vec2.sub(radiusCenter, fromOriginToPoint)
      mcontroller.setVelocity(vec2.add(vec2.mul(vec2.norm(world.distance(newLocation, mcontroller.position())), speed), vel))
    else
      controlTo(radiusCenter, speed)
    end
  else
    mcontroller.setVelocity(vel)
  end
end

function vec2.lerp(a, b, t)
  return {a[1] * (1-t) + (b[1]*t), a[2] * (1-t) + (b[2]*t)}
end

function vec2.lerp2(a, b, t)
  return {vec2.add(vec2.mul(vec2.sub(b[1], a[1]), t), 1.0), vec2.add(vec2.mul(vec2.sub(b[2], a[2]), t), 1.0)}
end
