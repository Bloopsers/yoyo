require "/scripts/vec2.lua"

function init()
  mcontroller.applyParameters({gravityEnabled = false})
  mcontroller.applyParameters(config.getParameter("movementSettings", {}))

  self.rotationSpeed = config.getParameter("rotationSpeed", 25)
  self.ownerId = nil
  self.fireMode = "primary"
  self.pickupDistance = config.getParameter("pickupDistance", 2)
  self.maxDistance = config.getParameter("maxDistance")
  self.yoyoTime = 0
  self.maxYoyoTime = config.getParameter("maxYoyoTime", 5)
  self.yoyoSpeed = config.getParameter("yoyoSpeed", 50) - 10
  self.yoyoLength = 0
  self.hits = 0
  self.dieOnReturn = config.getParameter("dieOnReturn", false)
  self.ownerId = projectile.sourceEntity()
  self.aimPosition = mcontroller.position()
  self.hitSounds = config.getParameter("hitSounds")
  self.rotation = 0

  mcontroller.setRotation(0)

  message.setHandler("updateProjectile", function(_, _, aimPosition, fireMode)
    self.aimPosition = aimPosition
    self.fireMode = fireMode
    return entity.id()
  end)

  if yoyoExtra then yoyoExtra:init() end
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

function returnYoyo()
  if self.dieOnReturn then
    projectile.die()
  else
    self.returning = true
  end
end

function update(dt)
  if yoyoExtra then
    yoyoExtra:update(dt)
  end

  self.yoyoTime = self.yoyoTime + (1 * dt)

  self.ownerPos = world.entityPosition(self.ownerId)
  self.yoyoLength = world.magnitude(mcontroller.position(), self.ownerPos)

  if self.yoyoTime >= self.maxYoyoTime or self.yoyoLength > self.maxDistance +3 or self.fireMode == "none" or world.pointTileCollision(mcontroller.position(), {"Block", "Dynamic", "Null"}) then
    returnYoyo()
  end
  
  world.debugPoly(circle(self.maxDistance, 32, self.ownerPos), {255, 255, 0})
  world.debugPoly(circle(world.magnitude(mcontroller.position(), self.ownerPos), 32, self.ownerPos), {0, 255, 0})
  world.debugText("%s/%s", self.yoyoLength, self.maxDistance, self.aimPosition, {0, 255, 0})

  if self.ownerId and world.entityExists(self.ownerId) then
    if self.aimPosition then
      if self.yoyoTime > 0.15 and self.returning == true then
        controlTo(self.ownerPos, self.yoyoSpeed * 2, 650)

        if world.lineTileCollision(mcontroller.position(), self.ownerPos, {"Block", "Dynamic", "Null"}) then
          mcontroller.applyParameters({collisionEnabled = false})
        end

        local toTarget = world.distance(self.ownerPos, mcontroller.position())

        if vec2.mag(toTarget) < self.pickupDistance and self.yoyoTime > 0.15 then
          projectile.die()
        end
      else
        local distToPos = world.magnitude(mcontroller.position(), self.aimPosition)
        
        controlTo(self.aimPosition, self.yoyoSpeed, 650)
      end
    end
  else
    projectile.die()
  end
  
  if self.returning == true then
    self.rotation = mcontroller.rotation() + (self.rotationSpeed * dt)
  else
    self.rotation = mcontroller.rotation() - (self.rotationSpeed * dt)
  end
  mcontroller.setRotation(self.rotation)
end

function controlTo(position, speed, controlForce)
  controlForce = 350
  local offset = world.distance(position, mcontroller.position())
  local v = vec2.clampMag(vec2.sub(position, self.ownerPos), self.maxDistance)

  local pos = vec2.approach(mcontroller.position(), vec2.add(self.ownerPos, v), speed / 60)

  if world.pointTileCollision(pos, {"Block", "Dynamic", "Null"}) or self.returning == true then
    controlTo2(position, speed, controlForce)
  else
    mcontroller.setPosition(pos)
  end
end

function controlTo2(position, speed, controlForce)
  local offset = world.distance(position, mcontroller.position())
  local v = vec2.sub(position, self.ownerPos)
  v = vec2.clampMag(v, self.maxDistance)
  offset = world.distance(vec2.add(self.ownerPos, v), mcontroller.position())
  mcontroller.approachVelocity(vec2.mul(vec2.norm(offset), speed), controlForce)
end

function vec2.length(vector)
  return math.sqrt(vec2.dot(vector, vector))
end

function vec2.clampMag(vector, maxLength)
  if vec2.length(vector) > maxLength then
    vector = vec2.norm(vector)
    vector = vec2.mul(vector, maxLength)
  end
  return vector
end

function hit(entityId)
  if yoyoExtra then
    yoyoExtra:hit(entityId)
  end

  if self.hitSounds then
    projectile.processAction({action = "sound", options = self.hitSounds})
  end
  if world.entityDamageTeam(entityId).type == "enemy" then
    world.sendEntityMessage(self.ownerId, "hitEnemy", entityId)
  end
  if self.yoyoTime > 0.15 then
    self.yoyoTime = self.yoyoTime +0.5
  end

  --shoot out the yoyo in a random direction if we hit something
  local directions = {
    {2100, 2100},
    {-2100, -2100},
    {2100, -2100},
    {-2100, 2100},
    {0, 2100},
    {0, -2100},
    {2100, 0},
    {-2100, 0}
  }
  mcontroller.force(directions[math.random(#directions)])
end
