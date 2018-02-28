require "/scripts/vec2.lua"

function init()
  mcontroller.applyParameters({
    gravityEnabled = false,
	  mass = 0,
    collisionPoly = {{-0.35, -0.35}, {0.35, -0.35}, {0, 0.35}, {-0.35, -0.35}}
  })

  self.switchTimer = 1
  radius = config.getParameter("rotateRadius", 5)
  rotateSpeed = config.getParameter("rotateSpeed", 1)
  local angles = { 0, 180, -180 }
  angle = angles[math.random(1, 3)]

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
  local ownerPos = world.entityPosition(self.ownerId)
  world.debugPoly(circle(radius, 32, ownerPos), {0, 255, 0})

  if mcontroller.isColliding() then
    self.switchTimer = self.switchTimer - 1
    if self.switchTimer == 0 then
      invertDirection()
    end
  else
    self.switchTimer = 1
  end

  angle = angle + (rotateSpeed * dt)
  mcontroller.setRotation(angle)

  local offset = vec2.mul({math.sin(angle), math.cos(angle)}, radius)

  controlTo(vec2.add(ownerPos, offset), 100)
end

function invertDirection()
  rotateSpeed = rotateSpeed - rotateSpeed * 2
end

function hit(entityId)
  invertDirection()
end

function controlTo(position, speed)
  local offset = world.distance(position, mcontroller.position())
  local vel = vec2.mul(vec2.norm(offset), speed)
  mcontroller.setVelocity(vel)
end
