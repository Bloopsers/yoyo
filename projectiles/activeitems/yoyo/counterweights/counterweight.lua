require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  mcontroller.applyParameters({
    gravityEnabled = false
  })
  mcontroller.applyParameters(config.getParameter("movementSettings", {}))

  self.returning = false
  self.time = 0
  self.pickupDistance = 1
  self.switchTimer = 0
  self.maxTime = config.getParameter("maxTime")
  self.dieOnReturn = config.getParameter("dieOnReturn")
  self.lastColliding = false

  self.maxDistance = 8
  self.speed = config.getParameter("rotateSpeed", 60)
  self.rotateSpeed = 0.02
  self.angle = math.random(360)

  self.ownerId = projectile.sourceEntity()
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

function returnCounterweight()
  if self.dieOnReturn then
    projectile.die()
  else
    self.returning = true
    mcontroller.applyParameters({collisionEnabled = false})
  end
end

function update(dt)
  self.ownerPos = world.entityPosition(self.ownerId)
  world.debugPoly(circle(self.maxDistance, 32, self.ownerPos), {0, 0, 255})

  self.time = self.time + (1 * dt)

  if self.time > self.maxTime then
    returnCounterweight()
  end

  if self.returning == true then
    controlTo2(self.ownerPos, self.speed, 350)

    if world.magnitude(mcontroller.position(), self.ownerPos) < self.pickupDistance then
      projectile.die()
    end
  else
    local pos = getNextPosition()
    if world.pointTileCollision(pos, {"Block", "Dynamic", "Null"}) and not self.lastColliding then
      self.rotateSpeed = -self.rotateSpeed
      pos = getNextPosition(2)
    end
    controlTo(pos, self.speed, 350)
    self.lastColliding = world.pointTileCollision(pos, {"Block", "Dynamic", "Null"})
  end

  mcontroller.setRotation(self.angle)
end

function getNextPosition(mod)
  mod = mod or 1
  self.angle = self.angle + (self.rotateSpeed * mod)
  local offset = vec2.mul({math.sin(self.angle), math.cos(self.angle)}, self.maxDistance)
  local pos = vec2.add(vec2.rotate(offset, self.angle * self.maxDistance), self.ownerPos)
  return pos
end
  
function hit(entityId)
  self.rotateSpeed = -self.rotateSpeed
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
  
function controlTo(position, speed, controlForce)
  local offset = world.distance(position, mcontroller.position())
  local v = vec2.clampMag(vec2.sub(position, self.ownerPos), self.maxDistance)

  local pos = vec2.approach(mcontroller.position(), vec2.add(self.ownerPos, v), speed / 60)

  if world.lineTileCollision(mcontroller.position(), pos, {"Block", "Dynamic", "Null"}) then

  end

  if world.lineTileCollision(mcontroller.position(), pos, {"Block", "Dynamic", "Null"}) or self.returning == true then
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

