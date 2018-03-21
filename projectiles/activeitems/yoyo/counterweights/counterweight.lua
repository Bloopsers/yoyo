require "/scripts/vec2.lua"

function init()
  mcontroller.applyParameters({
    gravityEnabled = false
  })
  mcontroller.applyParameters(config.getParameter("movementSettings", {}))

  self.switchTimer = 1
  self.returning = false
  self.time = 0
  self.pickupDistance = 1
  radius = config.getParameter("rotateRadius", 5)
  rotateSpeed = 0.1
  angle = 0

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

function update(dt)
  self.ownerPos = world.entityPosition(self.ownerId)
  world.debugPoly(circle(radius, 32, ownerPos), {0, 255, 0})

  self.time = self.time + (1 * dt)
  if self.time > 4 then
    self.returning = true
    mcontroller.applyParameters({collisionEnabled = false})
  end

  angle = angle + rotateSpeed

  mcontroller.setRotation(angle)

  local offset = vec2.mul({math.sin(angle), math.cos(angle)}, radius)

  if self.returning == true then
    controlTo(self.ownerPos, 30, 800)
    if world.magnitude(world.entityPosition(self.ownerId), mcontroller.position()) < self.pickupDistance then
      projectile.die()
    end
  else
    if world.pointCollision(vec2.add(self.ownerPos, offset), {"Block"}) then
      self.switchTimer = self.switchTimer - 1
      controlTo(vec2.add(self.ownerPos, offset), 30, 800)
      if self.switchTimer == 0 then
        rotateSpeed = -rotateSpeed
      end
    else
      self.switchTimer = 1
      controlTo(vec2.add(self.ownerPos, offset), 30, 800)
    end
  end
end

function hit(entityId)
  rotateSpeed = -rotateSpeed
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
  local v = vec2.sub(position, self.ownerPos)
  v = vec2.clampMag(v, radius)
  offset = world.distance(vec2.add(self.ownerPos, v), mcontroller.position())
  mcontroller.approachVelocity(vec2.mul(vec2.norm(offset), speed), controlForce)
end