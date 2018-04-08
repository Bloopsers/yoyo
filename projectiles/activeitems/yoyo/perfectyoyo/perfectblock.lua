require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  mcontroller.setVelocity(vec2.mul(mcontroller.velocity(), 0.8))
  self.homingDistance = config.getParameter("homingDistance", 20)
  self.rotationRate = config.getParameter("rotationRate")
  self.trackingLimit = config.getParameter("trackingLimit")
  self.controlMovement = config.getParameter("controlMovement")
  self.sourceEntity = projectile.sourceEntity()
  self.rotationSpeed = config.getParameter("rotationSpeed")
  self.queryParameters = {
    withoutEntityId = self.sourceEntity,
    includedTypes = {"monster"},
    order = "nearest"
  }

  mcontroller.setVelocity({math.random(-5, 5), math.random(-5, 5)})

  local ttlVariance = config.getParameter("timeToLiveVariance")
  if ttlVariance then
    projectile.setTimeToLive(projectile.timeToLive() + sb.nrand(ttlVariance))
  end
end

function update(dt)
  if not projectile.sourceEntity() or not world.entityExists(projectile.sourceEntity()) then
    projectile.die()
  end

  mcontroller.setRotation(mcontroller.rotation() + (self.rotationSpeed * dt))

  local pos = mcontroller.position()
  local candidates = world.entityQuery(pos, self.homingDistance, self.queryParameters)

  if #candidates == 0 then
    controlTo(world.entityPosition(self.sourceEntity))
  else
    local vel = mcontroller.velocity()
    local angle = vec2.angle(vel)

    for _, candidate in ipairs(candidates) do
      if world.entityCanDamage(self.sourceEntity, candidate) then
        local canPos = world.entityPosition(candidate)
        if not world.lineTileCollision(pos, canPos) then
          local toTarget = world.distance(canPos, pos)
          local toTargetAngle = util.angleDiff(angle, vec2.angle(toTarget))

          if math.abs(toTargetAngle) > self.trackingLimit then
            return
          end
          controlTo(canPos)
          break
        end
      end
    end
  end
end

function controlTo(position, speedModifier)
  speedModifier = speedModifier or 1
  local offset = world.distance(position, mcontroller.position())
  mcontroller.approachVelocity(vec2.mul(vec2.norm(offset), self.controlMovement.maxSpeed * speedModifier), self.controlMovement.controlForce * speedModifier)
end
