require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/activeitem/stances.lua"

function init()
  self.fireOffset = config.getParameter("fireOffset")
  rope = {}
  ropeIds = {}

  for index,params in pairs(config.getParameter("rope")) do
    rope[index] = {
      points = {},
      length = 0,
      params = params
    }
    params.hue = 0
    table.insert(ropeIds, index)
  end

  message.setHandler("hitEnemy", function(_, _, entityId)
    spawnCounterweights()
  end)

  self.lastFireMode = "none"
  counterweights = config.getParameter("counterweights")
  self.projectileType = config.getParameter("projectileType")
  self.fireMode = "none"
  self.yoyoRotation = 0
  self.projectileParameters = config.getParameter("projectileParameters")
  self.maxLength = config.getParameter("maxLength", 5) + config.getParameter("extraLength", 0)
  self.aimAngle = 0
  self.facingDirection = 0
  self.projectileId = nil
  self.projectilePosition = nil
  self.cooldownTime = config.getParameter("cooldownTime", 0)
  self.cooldownTimer = self.cooldownTime

  self.projectileParameters.power = self.projectileParameters.power * root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1))

  for index,counterweight in pairs(counterweights) do
    rope["counterWeight" .. index] = {
      points = {},
      length = 0,
      params = rope.yoyo.params
    }
    table.insert(ropeIds, "counterWeight" .. index)
    counterweight.projectileParameters.power = self.projectileParameters.power + (counterweight.projectileParameters.power or 0)
  end

  activeItem.setScriptedAnimationParameter("ropes", ropeIds)

  initStances()
  checkProjectiles()

  if storage.projectileIds then
    setStance("throw")
  else
    setStance("idle")
  end
end

function uninit()
  cancel()
end

function update(dt, fireMode, shiftHeld, moves)
  self.fireMode = fireMode

  self.aimAngle, self.facingDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
  activeItem.setFacingDirection(self.facingDirection)

  trackProjectile()

  if self.projectileId then
    setStance("throw")
    if world.entityExists(self.projectileId) then
      for id,counterweight in pairs(counterweights) do
        if counterweight.projId and world.entityExists(counterweight.projId) then
          counterweight.position = world.entityPosition(counterweight.projId)
          local position = mcontroller.position()
          local id = "counterWeight" .. id
          local handPosition = vec2.add(position, activeItem.handPosition(rope[id].params.visualOffset))

          updateRope(id, {handPosition, counterweight.position})
        else
          updateRope("counterWeight" .. id, {})
        end
      end
      world.sendEntityMessage(self.projectileId, "updateProjectile",
        activeItem.ownerAimPosition(),
        self.fireMode,
        rope.yoyo.length
      )

      local position = mcontroller.position()
      local handPosition = vec2.add(position, activeItem.handPosition(self.ropeOffset))

      updateRope("yoyo", {handPosition, self.projectilePosition})
    else
      cancel()
    end
  end

  updateStance(dt)
  checkProjectiles()

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.stanceName == "idle" and self.cooldownTimer == 0 then
    if (fireMode == "primary" or fireMode == "alt") and self.lastFireMode ~= ("primary" or "alt") then
      self.cooldownTimer = self.cooldownTime
      setStance("windup")
    end
  end

  self.lastFireMode = fireMode

  if self.stanceName == "throw" then
    if not self.projectileId then
      setStance("precatch")
      animator.playSound("catch")
    end
  end

  updateAim()
end

function trackProjectile()
  if self.projectileId then
    if world.entityExists(self.projectileId) then
      local position = mcontroller.position()
      self.projectilePosition = vec2.add(world.distance(world.entityPosition(self.projectileId), position), position)
    else
      cancel()
    end
  end
end

function spawnCounterweights()
  for index,counterweight in pairs(counterweights) do
    if counterweight.projId == nil or not world.entityExists(counterweight.projId) then
      counterweight.points = {}
      counterweight.projId = world.spawnProjectile(
        counterweight.projectileType,
        mcontroller.position(),
        activeItem.ownerEntityId(),
        {0, 0},
        false,
        counterweight.projectileParameters
      )
    end
  end
end

function fire()
  activeItem.setCursor("/cursors/reticle0.cursor")

  local params = copy(self.projectileParameters)
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.ownerAimPosition = activeItem.ownerAimPosition()
  params.maxDistance = self.maxLength

  if self.aimDirection < 0 then params.processing = "?flipx" end
  self.projectileId = world.spawnProjectile(
    self.projectileType,
    firePosition(),
    activeItem.ownerEntityId(),
    aimVector(),
    false,
    params
  )

  if self.projectileId then
    storage.projectileIds = {projectileId}
  end

  animator.playSound("throw")
end

function updateRope(id, newRope)
  local position = mcontroller.position()
  local previousRopeCount = #rope[id].points
  rope[id].points = newRope
  local ropeLength = 0

  if rope[id].params.rainbow == true then
    rope[id].params.hue = rope[id].params.hue +(rope[id].params.hueCycleSpeed or 1)
    rope[id].params.hue = rope[id].params.hue % 360
    rope[id].params.color = HSLtoRGB(rope[id].params.hue, 170, 170, (rope[id].params.color[4] or 255))
  end

  activeItem.setScriptedAnimationParameter(id .. "params", rope[id].params)

  for i = 2, #rope[id].points do
    ropeLength = ropeLength + world.magnitude(rope[id].points[i], rope[id].points[i - 1])
  end
  rope[id].length = ropeLength
  for i = #rope[id].points + 1, previousRopeCount do
  end

  activeItem.setScriptedAnimationParameter(id .. "points", rope[id].points)
end

function cancel()
  if self.projectileId and world.entityExists(self.projectileId) then
    world.callScriptedEntity(self.projectileId, "kill")
    activeItem.setCursor()
  end
  for k,v in pairs(counterweights) do
    if v.projId and world.entityExists(v.projId) then
      world.callScriptedEntity(v.projId, "kill")
    end
  end
  self.projectileId = nil
  self.projectilePosition = nil
  updateRope("yoyo", {})
  for i=1,#counterweights do
    updateRope("counterWeight" .. i, {})
  end
  status.clearPersistentEffects("grapplingHook"..activeItem.hand())
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

function checkProjectiles()
  if storage.projectileIds then
    local newProjectileIds = {}
    for i, projectileId in ipairs(storage.projectileIds) do
      if world.entityExists(projectileId) then
        local updatedProjectileIds = world.callScriptedEntity(projectileId, "projectileIds")

        if updatedProjectileIds then
          for j, updatedProjectileId in ipairs(updatedProjectileIds) do
            table.insert(newProjectileIds, updatedProjectileId)
          end
        end
      end
    end
    storage.projectileIds = #newProjectileIds > 0 and newProjectileIds or nil
  end
end

function HSLtoRGB(h, s, l, a)
    if s<=0 then return l,l,l   end
    h, s, l = h/360*6, s/255, l/255
    local c = (1-math.abs(2*l-1))*s
    local x = (1-math.abs(h%2-1))*c
    local m,r,g,b = (l-.5*c), 0,0,0
    if h < 1     then r,g,b = c,x,0
    elseif h < 2 then r,g,b = x,c,0
    elseif h < 3 then r,g,b = 0,c,x
    elseif h < 4 then r,g,b = 0,x,c
    elseif h < 5 then r,g,b = x,0,c
    else              r,g,b = c,0,x
    end return {(r+m)*255,(g+m)*255,(b+m)*255, a}
end
