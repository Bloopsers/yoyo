require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/activeitem/stances.lua"

function addProjectile(id, type, parameters, counterweight)
  local ropeDefaults = {
    line = {},
    color = {255, 255, 255, 255},
    rainbow = false,
    hue = 0,
    hueRange = {0, 360},
    hueCycleSpeed = 1,
    fullbright = false
  }
  self.projectiles[id] = {
    type = type,
    parameters = parameters,
    id = nil,
    position = {0, 0},
    counterweight = counterweight,
    rope = sb.jsonMerge(ropeDefaults, config.getParameter("rope"))
  }
end

function init()
  self.projectiles = {}

  addProjectile("yoyo", config.getParameter("projectileType"), config.getParameter("projectileParameters"))

  message.setHandler("hitEnemy", function(_, _, entityId)
    spawnCounterweights()
  end)

  self.lastFireMode = "none"
  self.fireMode = "none"
  self.fireOffset = config.getParameter("fireOffset")
  self.maxLength = config.getParameter("maxLength", 5) + config.getParameter("extraLength", 0)
  self.aimAngle = 0
  self.facingDirection = 0
  self.counterweights = config.getParameter("counterweights", {})
  self.activeCounterweight = 1

  self.projectiles.yoyo.parameters.power = self.projectiles.yoyo.parameters.power * root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1))

  for index,counterweight in pairs(self.counterweights) do
    counterweight.projectileParameters.power = self.projectiles.yoyo.parameters.power * (counterweight.projectileParameters.powerScale or 0)
    addProjectile("counterWeight" .. index, counterweight.projectileType, counterweight.projectileParameters, index)
  end

  initStances()
  setStance("idle")
end

function uninit()
  cancel()
end

function updateRopes()
  for index,projectile in pairs(self.projectiles) do
    if projectile.rope.rainbow then
      projectile.rope.hue = projectile.rope.hue + projectile.rope.hueCycleSpeed
      if projectile.rope.hue > projectile.rope.hueRange[2] then
        projectile.rope.hue = projectile.rope.hueRange[1]
      end
      projectile.rope.color = HSLtoRGB(projectile.rope.hue, 170, 170, 255)
    end
  end
end

function update(dt, fireMode, shiftHeld, moves)
  activeItem.setScriptedAnimationParameter("projectiles", self.projectiles)
  self.fireMode = fireMode

  self.aimAngle, self.facingDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
  activeItem.setFacingDirection(self.facingDirection)

  trackProjectiles()
  updateRopes()
  updateStance(dt)

  if self.stanceName == "idle" then
    if (fireMode == "primary" or fireMode == "alt") and not (self.lastFireMode == "primary" or self.lastFireMode == "alt") then
      setStance("windup")
    end
  end

  self.lastFireMode = fireMode

  if self.stanceName == "throw" then
    if not self.projectiles.yoyo.id or not world.entityExists(self.projectiles.yoyo.id) then
      setStance("precatch")
      animator.playSound("catch")
    end
  end

  updateAim()
end

function trackProjectiles()
  for index,projectile in pairs(self.projectiles) do
    if projectile.id and world.entityExists(projectile.id) then
      projectile.position = world.entityPosition(projectile.id)
    else
      -- cycle counterweight after the projectile dies
      if projectile.counterweight and (projectile.id and not world.entityExists(projectile.id)) then
        projectile.id = nil
        self.activeCounterweight = self.activeCounterweight +1
        if self.activeCounterweight > #self.counterweights then self.activeCounterweight = 1 end
      end
    end
  end
  if self.projectiles.yoyo.id and world.entityExists(self.projectiles.yoyo.id) then
    world.sendEntityMessage(self.projectiles.yoyo.id, "updateProjectile",
      activeItem.ownerAimPosition(),
      self.fireMode
    )
  else
    cancel()
  end
end

function spawnCounterweights()
  local currentCounterweight = self.projectiles["counterWeight"..self.activeCounterweight]
  if currentCounterweight and not currentCounterweight.id then
    local proj = self.projectiles["counterWeight"..self.activeCounterweight]
    self.projectiles["counterWeight"..self.activeCounterweight].id = world.spawnProjectile(
      proj.type,
      mcontroller.position(),
      activeItem.ownerEntityId(),
      {0, 0},
      false,
      proj.parameters
    )
  end
end

function fire()
  local parameters = copy(self.projectiles.yoyo.parameters)
  parameters.powerMultiplier = activeItem.ownerPowerMultiplier()
  parameters.ownerAimPosition = activeItem.ownerAimPosition()
  parameters.maxDistance = self.maxLength

  self.projectiles.yoyo.id = world.spawnProjectile(
    self.projectiles.yoyo.type,
    firePosition(),
    activeItem.ownerEntityId(),
    aimVector(),
    false,
    parameters
  )

  animator.playSound("throw")
end

function cancel()
  for index,projectile in pairs(self.projectiles) do
    if projectile.id and world.entityExists(projectile.id) then
      world.callScriptedEntity(projectile.id, "kill")
    end
  end
end

function firePosition()
  local entityPos = mcontroller.position()
  local barrelOffset = activeItem.handPosition(self.fireOffset)
  local barrelPosition = vec2.add(entityPos, barrelOffset)
  local collidePoint = world.lineCollision(entityPos, barrelPosition)
  if collidePoint then
    return vec2.add(entityPos, vec2.mul(barrelOffset, vec2.mag(barrelOffset) - 0.5))
  else
    return barrelPosition
  end
end

function HSLtoRGB(h, s, l, a)
  if s <= 0 then return {l, l, l, 255} end
  h, s, l = h/360*6, s/255, l/255
  local c = (1-math.abs(2*l-1))*s
  local x = (1-math.abs(h%2-1))*c
  local m,r,g,b = (l-.5*c), 0,0,0
  if h < 1 then r,g,b = c,x,0
  elseif h < 2 then r,g,b = x,c,0
  elseif h < 3 then r,g,b = 0,c,x
  elseif h < 4 then r,g,b = 0,x,c
  elseif h < 5 then r,g,b = x,0,c
  else r,g,b = c,0,x
  end return {(r+m)*255,(g+m)*255,(b+m)*255, a}
end
