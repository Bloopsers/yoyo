require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  mcontroller.setVelocity({0, 0})
  self.homingDistance = config.getParameter("homingDistance", 20)
  self.rotationRate = config.getParameter("rotationRate")
  self.trackingLimit = config.getParameter("trackingLimit")
  self.controlMovement = config.getParameter("controlMovement")
  self.sourceEntity = projectile.sourceEntity()
  self.queryParameters = {
    withoutEntityId = self.sourceEntity,
    includedTypes = {"creature"},
    order = "nearest"
  }

  local ttlVariance = config.getParameter("timeToLiveVariance")
  if ttlVariance then
    projectile.setTimeToLive(projectile.timeToLive() + sb.nrand(ttlVariance))
  end
end

function update(dt)
  local pos = mcontroller.position()
  local candidates = world.entityQuery(pos, self.homingDistance, self.queryParameters)

  if #candidates == 0 then return end

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

  mcontroller.setRotation(math.atan(vel[2], vel[1]))
end

function controlTo(position)
  local offset = world.distance(position, mcontroller.position())
  mcontroller.approachVelocity(vec2.mul(vec2.norm(offset), self.controlMovement.maxSpeed), self.controlMovement.controlForce)
end
