require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.trailParticle = config.getParameter("trailParticle")
  self.emitterTimer = 0
  self.color = 0
  self.colors = {
    "f4988c",
    "ffd495",
    "ffffa7",
    "b2e89d",
    "96cbe7",
    "d29ce7",
    "eab3db"
  }
  self.targetPosition = {0, 0}
  self.controlMovement = config.getParameter("controlMovement")
end

function update(dt)
  if not world.entityExists(projectile.sourceEntity()) then
    projectile.die()
  end
  controlTo(world.entityPosition(projectile.sourceEntity()))

  local toTarget = world.distance(world.entityPosition(projectile.sourceEntity()), mcontroller.position())

  if vec2.mag(toTarget) < 1 then
    projectile.die()
  end

  self.emitterTimer = self.emitterTimer + 1

  if self.emitterTimer > 1 then
    self.color = self.color + 1
    if self.color > #self.colors then self.color = 1 end
    local color = hex2rgb(self.colors[self.color])
    self.trailParticle.specification.color = color
    projectile.processAction(self.trailParticle)
    self.emitterTimer = 0
  end
end

function controlTo(position)
  local offset = world.distance(position, mcontroller.position())
  mcontroller.approachVelocity(vec2.mul(vec2.norm(offset), self.controlMovement.maxSpeed), self.controlMovement.controlForce)
end

function hex2rgb(hex)
  hex = hex:gsub("#","")
  return {tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))}
end