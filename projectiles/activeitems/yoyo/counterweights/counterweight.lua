require "/scripts/vec2.lua"

function init()
  mcontroller.applyParameters({
    gravityEnabled = false
  })
  mcontroller.applyParameters(config.getParameter("movementSettings", {}))

  self.returning = false
  self.time = 0
  self.pickupDistance = 1
  self.switchTimer = 0
  self.fixedAngle = config.getParameter("fixedAngle")
  self.maxTime = config.getParameter("maxTime")
  self.radius = config.getParameter("rotateRadius", 6)
  self.rotateSpeed = config.getParameter("rotateSpeed", 8)
  self.dieOnReturn = config.getParameter("dieOnReturn")

  if self.fixedAngle then
    self.angle = self.fixedAngle
  else
    self.angle = math.random(360)
  end

  self.ownerId = projectile.sourceEntity()
  self.lastSafePlace = world.entityPosition(self.ownerId)
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
  world.debugPoly(circle(self.radius, 32, self.ownerPos), {0, 0, 255})

  self.time = self.time + (1 * dt)

  if self.time > self.maxTime then
    returnCounterweight()
  end

  if self.returning == true then
    controlTo2(self.ownerPos, 50, 300)

    if vec2.mag(world.distance(mcontroller.position(), self.ownerPos)) < self.pickupDistance then
      projectile.die()
    end
  else
    self.angle = self.angle + (self.rotateSpeed * dt)

    mcontroller.setRotation(self.angle)

    local offset = vec2.mul({math.sin(self.angle), math.cos(self.angle)}, self.radius)
    local pos = vec2.add(self.ownerPos, offset)

    mcontroller.setPosition(pos)
  end
end

function hit(entityId)
  self.rotateSpeed = -self.rotateSpeed
end

function vec2.length(vector)
  return math.sqrt(vec2.dot(vector, vector))
end

function vec2.lerp(a, b, t)
  return {a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t}
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
  v = vec2.clampMag(v, self.radius)
  offset = world.distance(vec2.add(self.ownerPos, v), mcontroller.position())
  mcontroller.approachVelocity(vec2.mul(vec2.norm(offset), speed), controlForce)
end