require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rope.lua"
require "/scripts/activeitem/stances.lua"


function init()
  self.fireOffset = config.getParameter("fireOffset")
  self.ropeOffset = config.getParameter("ropeOffset")
  self.ropeVisualOffset = config.getParameter("ropeVisualOffset")
  self.consumeOnUse = config.getParameter("consumeOnUse")
  self.projectileType = config.getParameter("projectileType")
  self.projectileParameters = config.getParameter("projectileParameters")

  self.reelInDistance = config.getParameter("reelInDistance")
  self.reelOutLength = config.getParameter("reelOutLength")
  self.breakLength = config.getParameter("breakLength")
  self.minSwingDistance = config.getParameter("minSwingDistance")
  self.reelSpeed = config.getParameter("reelSpeed")
  self.controlForce = config.getParameter("controlForce")
  self.groundLagTime = config.getParameter("groundLagTime")

  self.rope = {}
  self.ropeLength = 0
  self.aimAngle = 0
  self.onGround = false
  self.onGroundTimer = 0
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
  
  trackGround(dt)
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

      if not self.anchored and self.ropeLength > self.reelOutLength then
        cancel()
      end
    else
      cancel()
    end
  end

  if self.ropeLength > self.breakLength then
    world.sendEntityMessage(self.projectileId, "tooFar", true)
  end
  
  updateStance(dt)
  checkProjectiles()

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.stanceName == "idle" and fireMode == "primary" and self.cooldownTimer == 0 then
    self.cooldownTimer = self.cooldownTime
    setStance("windup")
  end

  if self.stanceName == "throw" then
    if not storage.projectileIds then
      setStance("catch")
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

function trackGround(dt)
  if mcontroller.onGround() then
    self.onGround = true
    self.onGroundTimer = self.groundLagTime
  else
    self.onGroundTimer = self.onGroundTimer - dt
    if self.onGroundTimer < 0 then
      self.onGround = false
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
  if self.projectileId and self.anchored and self.consumeOnUse then
    item.consume(1)
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