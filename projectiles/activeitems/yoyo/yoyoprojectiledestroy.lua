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
  self.cursorOutside = false
  self.maxYoyoTime = config.getParameter("maxYoyoTime", 5)
  self.yoyoSpeed = config.getParameter("yoyoSpeed", 32)
  self.stringLength = 0
  self.allowMove = true
  self.hits = 0
  self.variable = 0
  self.ownerId = projectile.sourceEntity()
  self.aimPosition = mcontroller.position()
  self.hitSounds = config.getParameter("hitSounds")
  self.rotation = 0
  mcontroller.setRotation(self.rotation)
    
  self.queryParameters = {
    includedTypes = {"creature"},
    order = "nearest"
  }

  message.setHandler("updateProjectile", function(_, _, aimPosition, fireMode, stringLength)
    self.aimPosition = aimPosition
    self.fireMode = fireMode
    self.stringLength = stringLength
    return entity.id()
  end)

  if yoyoExtra then
    yoyoExtra:init()
  end
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
  if yoyoExtra then
    yoyoExtra:update(dt)
  end

  local qur = world.entityQuery(mcontroller.position(), 8, self.queryParameters)
  for _,entityId in ipairs(qur) do
    if world.entityDamageTeam(entityId).type == "enemy" then
      world.debugLine(mcontroller.position(), world.entityPosition(entityId), {255, 255, 0})
    end
  end

  self.yoyoTime = self.yoyoTime + (1 * dt)

  self.ownerPos = world.entityPosition(self.ownerId)

  --world.damageTileArea(mcontroller.position(), 2, "foreground", self.ownerPos, "blockish", 0.5)

  if self.yoyoTime >= self.maxYoyoTime or self.stringLength > self.maxDistance +5 or self.fireMode == "none" then
    self.returning = true
    projectile.die()
    mcontroller.applyParameters({collisionEnabled = false})
  end
  
  world.debugPoly(circle(self.maxDistance, 32, self.ownerPos), {255, 255, 0})
  world.debugPoly(circle(world.magnitude(mcontroller.position(), self.ownerPos), 32, self.ownerPos), {0, 255, 0})
  world.debugText("%s", sb.printJson(mcontroller.velocity()), self.aimPosition, {0, 255, 0})

  if self.ownerId and world.entityExists(self.ownerId) then
    if self.aimPosition then
      if self.yoyoTime > 0.15 and self.returning == true then
        controlTo(self.ownerPos, self.yoyoSpeed * 2, 650)
        local toTarget = world.distance(self.ownerPos, mcontroller.position())

        if vec2.mag(toTarget) < self.pickupDistance and self.yoyoTime > 0.15 then
          projectile.die()
        end
      else
        local distToPos = world.magnitude(mcontroller.position(), self.aimPosition)
		local cursorOutside = world.magnitude(self.ownerPos, self.aimPosition) > self.maxDistance
        if distToPos < 0.4 then
          controlTo(self.aimPosition, 0, 650)
        elseif distToPos < 0.6 then
          controlTo(self.aimPosition, self.yoyoSpeed / 3, 650)
        elseif distToPos < 1.0 then
          controlTo(self.aimPosition, self.yoyoSpeed / 2.2, 650)
        elseif distToPos < 1.4 then
          controlTo(self.aimPosition, self.yoyoSpeed / 1.4, 650)
        else
          controlTo(self.aimPosition, self.yoyoSpeed, 650)
        end
		
		if cursorOutside == true then
		    if world.magnitude(mcontroller.position(), self.ownerPos) >= self.maxDistance then
				mcontroller.setVelocity({mcontroller.yVelocity() / 24, mcontroller.xVelocity() / 24})
				controlTo(self.aimPosition, self.yoyoSpeed / 4.5, 650 / 4.5)
				controlTwo(mcontroller.position(), self.yoyoSpeed / 4.5, 650 / 4.5)
			end
		end
		
		if world.magnitude(mcontroller.position(), self.ownerPos) > self.maxDistance + 0.2 then
          controlTo(self.ownerPos, self.yoyoSpeed, 650)
		end
      end
    end
  else
    projectile.die()
  end

  if self.variable > 0 then
  self.variable = self.variable - dt
  end
  if self.variable < 0 then
  self.variable = 0
  end
  
  if self.returning == true then
    self.rotation = mcontroller.rotation() + (self.rotationSpeed * dt)
  else
    self.rotation = mcontroller.rotation() - (self.rotationSpeed * dt)
  end
  mcontroller.setRotation(self.rotation)
end

function controlTo(position, speed, controlForce)
  local offset = world.distance(position, mcontroller.position())
  local v = vec2.sub(position, self.ownerPos)
  v = vec2.clampMag(v, self.maxDistance)
  offset = world.distance(vec2.add(self.ownerPos, v), mcontroller.position())
  if world.magnitude(mcontroller.position(), self.ownerPos) > self.maxDistance -1.5 then
    controlForce = 900
  end
  mcontroller.approachVelocity(vec2.mul(vec2.norm(offset), speed), controlForce)
end

function controlTwo(position, speed, controlForce)
  local offset = world.distance(position, mcontroller.position())
  local v = vec2.sub(position, self.ownerPos)
  v = vec2.clampMag(v, self.maxDistance)
  offset = world.distance(vec2.add(self.ownerPos, v), mcontroller.position())
  if world.magnitude(mcontroller.position(), self.ownerPos) > self.maxDistance -1.5 then
    controlForce = 900
  end
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

function controlTo2(position, speed, controlForce)
  local offset = world.distance(position, mcontroller.position())
  local v = vec2.sub(position, self.ownerPos)
  v = vec2.clampMag(v, self.maxDistance)[1]
  offset = world.distance(vec2.add(self.ownerPos, v), mcontroller.position())
  local vel = vec2.mul(vec2.norm(offset), speed)
  mcontroller.setVelocity(vel)
end

function hit(entityId)
  if yoyoExtra then
    yoyoExtra:hit(entityId)
  end

  if self.hitSounds then
    projectile.processAction({action = "sound", options = self.hitSounds})
  end
  if world.entityDamageTeam(entityId).type == "enemy" then
    self.hits = self.hits +1
  end
  if self.hits >= 2 then
    world.sendEntityMessage(self.ownerId, "hitEnemy", entityId)
    self.hits = 0
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
