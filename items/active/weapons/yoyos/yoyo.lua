require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rope.lua"
require "/scripts/activeitem/stances.lua"


function init()
  self.fireOffset = config.getParameter("fireOffset")
  self.ropeOffset = config.getParameter("ropeOffset")
  self.ropeVisualOffset = config.getParameter("ropeVisualOffset")
  self.projectileType = config.getParameter("projectileType")
  self.oldString = config.getParameter("oldString")
  self.currentString = config.getParameter("currentString")
  self.noMore = false
  if self.currentString and not self.noMore then
  self.noMore = true
  activeItem.setInstanceValue("oldString", self.currentString)
  end
  self.shouldGiveString = config.getParameter("shouldGiveString")
  self.projectileParameters = config.getParameter("projectileParameters")
  activeItem.setInstanceValue("shouldGiveString", false)

  activeItem.setInstanceValue("description", config.getParameter("originalDescription") .. "\nLength: " .. config.getParameter("maxLength") + config.getParameter("extraLength"))


  self.extraLength = config.getParameter("extraLength", 0)
  self.maxLength = config.getParameter("maxLength") + self.extraLength

  self.rope = {}
  self.ropeLength = 0
  self.aimAngle = 0
  self.facingDirection = 0
  self.projectileId = nil
  self.projectilePosition = nil
  self.anchored = false
  self.previousMoves = {}
  self.previousFireMode = nil
  self.overrideHoverTime = config.getParameter("overrideHoverTime")

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
      local position = mcontroller.position()
      local handPosition = vec2.add(position, activeItem.handPosition(self.ropeOffset))
	  world.sendEntityMessage(self.projectileId, "updateProjectile", activeItem.ownerAimPosition())
	  
	  if fireMode == "primary" then
		world.sendEntityMessage(self.projectileId, "updateHolding", self.overrideHoverTime)
	  elseif firemode ~= "primary" then
		world.sendEntityMessage(self.projectileId, "notClicking", false)
	  end
	  
	  if fireMode == "primary" then
		world.sendEntityMessage(self.projectileId, "leftClicking", true)
	  elseif firemode ~= "primary" then
		world.sendEntityMessage(self.projectileId, "leftClicking", false)
	  end
	  
	  world.sendEntityMessage(self.projectileId, "ownerPos", position)

      local newRope
      if #self.rope == 0 then
        newRope = {handPosition, self.projectilePosition}
      else
        newRope = copy(self.rope)
        table.insert(newRope, 1, world.nearestTo(newRope[1], handPosition))
        table.insert(newRope, world.nearestTo(newRope[#newRope], self.projectilePosition))
      end

      windRope(newRope)
      updateRope(newRope)

    else
      cancel()
    end
  end
  
  activeItem.setInstanceValue("description", config.getParameter("originalDescription") .. "\nLength: " .. config.getParameter("maxLength") + config.getParameter("extraLength"))

  if self.ropeLength > self.maxLength then
    world.sendEntityMessage(self.projectileId, "tooFar", true)
  end
  
  self.tooFarLength = self.maxLength + 1
  if self.ropeLength > self.tooFarLength then
    world.sendEntityMessage(self.projectileId, "wayTooFar", true)
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

function cancel()
  if self.projectileId and world.entityExists(self.projectileId) then
    world.callScriptedEntity(self.projectileId, "kill")
  end
  self.projectileId = nil
  self.projectilePosition = nil
  self.anchored = false
  updateRope({})
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

function updateRope(newRope)
  local position = mcontroller.position()
  local previousRopeCount = #self.rope
  self.rope = newRope
  self.ropeLength = 0

  activeItem.setScriptedAnimationParameter("ropeOffset", self.ropeVisualOffset)
  for i = 2, #self.rope do
    self.ropeLength = self.ropeLength + world.magnitude(self.rope[i], self.rope[i - 1])
    activeItem.setScriptedAnimationParameter("p" .. i, self.rope[i])
  end
  for i = #self.rope + 1, previousRopeCount do
    activeItem.setScriptedAnimationParameter("p" .. i, nil)
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