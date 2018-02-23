require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/yoyorope.lua"
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
    },
    table.insert(ropeIds, index)
  end

  counterweights = config.getParameter("counterweights")

  for index,counterweight in pairs(counterweights) do
    rope["counterWeight" .. index] = {
      points = {},
      length = 0,
      params = counterweight.rope
    }
    table.insert(ropeIds, "counterWeight" .. index)
  end

  activeItem.setScriptedAnimationParameter("ropes", ropeIds)

  self.projectileType = config.getParameter("projectileType")
  self.oldString = config.getParameter("oldString")
  self.currentStringType = config.getParameter("currentStringType")

  self.secondary = config.getParameter("secondary")
  self.secondaryTimer = 0
  self.leftClicking = false

  if self.secondary then
    self.secondary.projectileParameters.power = self.secondary.projectileParameters.power * root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1)) / 2
  end

  self.projectileParameters = config.getParameter("projectileParameters")

  self.maxLength = config.getParameter("maxLength", 5) + config.getParameter("extraLength", 0)

  self.aimAngle = 0
  self.facingDirection = 0
  self.projectileId = nil
  self.projectilePosition = nil
  self.anchored = false
  self.previousFireMode = nil

  self.projectileParameters.power = self.projectileParameters.power * root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1))
  initStances()

  self.cooldownTime = config.getParameter("cooldownTime", 0)
  self.cooldownTimer = self.cooldownTime

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
  self.previousFireMode = fireMode

  self.secondaryTimer = self.secondaryTimer + (1 * dt)

  self.leftClicking = fireMode == "primary"

  self.aimAngle, self.facingDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
  activeItem.setFacingDirection(self.facingDirection)

  if self.shouldGiveString == true then
	  self.shouldGiveString = false
	  activeItem.setInstanceValue("shouldGiveString", false)

	  player.giveItem(self.oldString)
  end

  trackProjectile()

  if self.projectileId then
    setStance("throw")
    if world.entityExists(self.projectileId) then
      for id,counterweight in pairs(counterweights) do
        if world.entityExists(counterweight.projId) then
          counterweight.position = world.entityPosition(counterweight.projId)
          local position = mcontroller.position()
          local id = "counterWeight" .. id
          local handPosition = vec2.add(position, activeItem.handPosition(rope[id].params.visualOffset))

          updateRope(id, {handPosition, counterweight.position})
        end
      end
      world.sendEntityMessage(self.projectileId, "updateProjectile", activeItem.ownerAimPosition())
      world.sendEntityMessage(self.projectileId, "leftClicking", self.leftClicking)

      if self.secondary and fireMode == "primary" then
        if self.secondaryTimer > self.secondary.emissionCycle then
	        local secParams = copy(self.secondary)
	        secParams.powerMultiplier = activeItem.ownerPowerMultiplier()
	        secParams.ownerAimPosition = activeItem.ownerAimPosition()

		      self.secProjectileId = world.spawnProjectile(
		        self.secondary.projectileType,
		        self.projectilePosition,
		        activeItem.ownerEntityId(),
		        {0, 0},
		        false,
		        secParams
		      )
          self.secondaryTimer = 0
        end
	    end

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

  if self.stanceName == "idle" and fireMode == "primary" and self.cooldownTimer == 0 then
    self.cooldownTimer = self.cooldownTime
    setStance("windup")
  end

  if self.stanceName == "throw" then
    if not self.projectileId then
      setStance("precatch")
    end
  end

  updateAim()
end

function trackCounterweights()
  for index,counterweight in pairs(counterweights) do
    if counterweight.projId then
      if world.entityExists(counterweight.projId) then
        local position = mcontroller.position()
        counterweight.position = vec2.add(world.distance(world.entityPosition(counterweight.projId), position), position)
      else
        counterweight.projId = nil
      end
    end
  end
end

function trackProjectile()
  if self.projectileId then
    if world.entityExists(self.projectileId) then
      local position = mcontroller.position()
      self.projectilePosition = vec2.add(world.distance(world.entityPosition(self.projectileId), position), position)
      if not self.anchored then
        self.anchored = world.callScriptedEntity(self.projectileId, "anchored")
      end
    else
      cancel()
    end
  end
end

function fire()
  if world.lineTileCollision(mcontroller.position(), firePosition()) then
    setStance("idle")
    return
  end

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

  for index,counterweight in pairs(counterweights) do
    counterweight.projId = world.spawnProjectile(
      counterweight.projectileType,
      mcontroller.position(),
      activeItem.ownerEntityId(),
      aimVector(),
      false,
      counterweight.projectileParameters
    )
  end

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

  activeItem.setScriptedAnimationParameter(id .. "params", rope[id].params)

  for i = 2, #rope[id].points do
    ropeLength = ropeLength + world.magnitude(rope[id].points[i], rope[id].points[i - 1])
    activeItem.setScriptedAnimationParameter(id .. "p" .. i, rope[id].points[i])
  end
  rope[id].length = ropeLength
  for i = #rope[id].points + 1, previousRopeCount do
    activeItem.setScriptedAnimationParameter(id .. "p" .. i, nil)
  end
end

function cancel()
  if self.projectileId and world.entityExists(self.projectileId) then
    world.callScriptedEntity(self.projectileId, "kill")
  end
  for k,v in pairs(counterweights) do
    if v.projId and world.entityExists(v.projId) then
      world.callScriptedEntity(v.projId, "kill")
    end
  end
  self.projectileId = nil
  self.projectilePosition = nil
  self.anchored = false
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
