require "/scripts/vec2.lua"
require "/scripts/yoyoutils.lua"

function init()
	mcontroller.applyParameters(config.getParameter("movementSettings", {}))
	mcontroller.setRotation(0)

	--Yoyo properties
	self.rotationSpeed = config.getParameter("rotationSpeed", 15)
	self.pickupDistance = config.getParameter("pickupDistance", 2)
	self.maxDistance = config.getParameter("maxDistance")
	self.dieOnReturn = config.getParameter("dieOnReturn", false)
	self.maxYoyoTime = config.getParameter("maxYoyoTime", 5)
	self.yoyoSpeed = config.getParameter("yoyoSpeed", 50) - 10
	self.useShift = config.getParameter("useShift", false)
	self.hitSounds = config.getParameter("hitSounds")
	self.defaultPower = config.getParameter("power", 0)

	self.fireMode = "primary"
	self.yoyoTime = 0
	self.yoyoLength = 0
	self.ownerId = projectile.sourceEntity()
	self.aimPosition = mcontroller.position()
	self.rotation = 0
	self.shiftHeld = false
	
	self.dualWieldingAnchorId = nil
	self.dualWieldingAnchorReturning = false

	--Constants
	self.forceReturnDistance = self.maxDistance + 3
	self.durationBeforeReturnable = 0.15
	self.anchorDistance = 1.5

	message.setHandler("updateProjectile", function(_, _, aimPosition, fireMode, shiftHeld, dualWieldingAnchorId)
		self.aimPosition = aimPosition
		self.fireMode = fireMode
		self.shiftHeld = shiftHeld
		self.dualWieldingAnchorId = dualWieldingAnchorId
		return entity.id()
	end)

	projectile.setTimeToLive(self.maxYoyoTime + 10)
  
	if yoyoExtra then yoyoExtra:init() end
end

function update(dt)
	if yoyoExtra then
		yoyoExtra:update(dt)
		if self.shiftHeld and self.useShift then
			yoyoExtra:shiftHeld()
		end
	end

	self.ownerPos = world.entityPosition(self.ownerId)
	self.yoyoTime = self.yoyoTime + (1 * dt)
	self.yoyoLength = world.magnitude(mcontroller.position(), self.ownerPos)

	if self.yoyoTime >= self.maxYoyoTime or self.yoyoLength > self.forceReturnDistance or self.fireMode == "none" then
		returnYoyo()
	end

	if self.dualWieldingAnchorId and self.dualWieldingAnchorId ~= entity.id() and world.entityExists(self.dualWieldingAnchorId) then
		projectile.setPower(self.defaultPower * 0.3)
	else
		projectile.setPower(self.defaultPower)
	end

	world.debugPoly(yoyoUtils.circlePoly(self.maxDistance, 32, self.ownerPos), {255, 255, 0})
	world.debugPoly(yoyoUtils.circlePoly(world.magnitude(mcontroller.position(), self.ownerPos), 32, self.ownerPos), {0, 255, 0})
	world.debugText("%s/%s", self.yoyoLength, self.maxDistance, self.aimPosition, {0, 255, 0})
	world.debugText("anchorReturning = %s", self.dualWieldingAnchorReturning, vec2.add(self.aimPosition, 2), {255, 255, 0})

	if self.ownerId and world.entityExists(self.ownerId) then
		if self.aimPosition then
			if self.yoyoTime > self.durationBeforeReturnable and self.returning then
				--Returning behavior
				controlTo(self.ownerPos, self.yoyoSpeed * 2, 650)

				if world.lineTileCollision(mcontroller.position(), self.ownerPos, {"Block", "Dynamic", "Null"}) then
					mcontroller.applyParameters({collisionEnabled = false})
				end

				local toTarget = world.distance(self.ownerPos, mcontroller.position())
				if vec2.mag(toTarget) <= self.pickupDistance and self.yoyoTime > self.durationBeforeReturnable then
					kill()
				end
			else
				--Normal behavior
				local distToPos = world.distance(mcontroller.position(), self.aimPosition)

				if not self.dualWieldingAnchorReturning and self.dualWieldingAnchorId and self.dualWieldingAnchorId ~= entity.id() and world.entityExists(self.dualWieldingAnchorId) then
					world.debugPoint(world.entityPosition(self.dualWieldingAnchorId), {255, 255, 0})

					controlTo(vec2.add(world.entityPosition(self.dualWieldingAnchorId), vec2.mul({math.cos(self.rotation), math.sin(self.rotation)}, self.anchorDistance)), self.yoyoSpeed, 650, true)
				else
					controlTo(self.aimPosition, self.yoyoSpeed, 650, false)
				end
			end
		end
	else
		kill()
	end

  -- 1 for counterclockwise, -1 for clockwise
  local direction = self.returning and 1 or -1
  self.rotation = mcontroller.rotation() + ((self.rotationSpeed * dt) * direction)
  mcontroller.setRotation(self.rotation)
end

function controlTo(position, speed, controlForce, ignoreMaxRange)
	controlForce = 350
	local offset = world.distance(position, mcontroller.position())
	local v = vec2.sub(position, self.ownerPos)
	if not ignoreMaxRange then
		v = yoyoUtils.clampMag(v, self.maxDistance)
	end

	local pos = vec2.approach(mcontroller.position(), vec2.add(self.ownerPos, v), speed / 60)

	if world.pointTileCollision(pos, {"Block", "Dynamic", "Null"}) or self.returning then
		controlToApproach(position, speed, controlForce)
	else
		mcontroller.setPosition(pos)
	end
end

function controlToApproach(position, speed, controlForce)
	local offset = world.distance(position, mcontroller.position())
	local v = vec2.sub(position, self.ownerPos)
	v = yoyoUtils.clampMag(v, self.maxDistance)
	offset = world.distance(vec2.add(self.ownerPos, v), mcontroller.position())
	mcontroller.approachVelocity(vec2.mul(vec2.norm(offset), speed), controlForce)
end

function hit(entityId)
	if yoyoExtra then
		yoyoExtra:hit(entityId)
	end

	if self.hitSounds then
		projectile.processAction({action = "sound", options = self.hitSounds})
	end
	if world.entityDamageTeam(entityId).type == "enemy" then
		world.sendEntityMessage(self.ownerId, "yoyos:hitEnemy", entityId)
	end
end

function returnYoyo()
	if self.dieOnReturn then
		kill()
	else
		self.returning = true
		if self.dualWieldingAnchorId and self.dualWieldingAnchorId == entity.id() then
			world.sendEntityMessage(self.ownerId, "yoyos:syncState/primary", entity.id(), self.returning)
			world.sendEntityMessage(self.ownerId, "yoyos:syncState/alt", entity.id(), self.returning)
		end
	end
end

function syncAnchorState(returning)
	self.dualWieldingAnchorReturning = returning
end

function kill()
	projectile.die()
end
