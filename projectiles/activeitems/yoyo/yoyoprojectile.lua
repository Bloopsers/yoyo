require "/scripts/vec2.lua"

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

  self.fireMode = "primary"
  self.yoyoTime = 0
  self.yoyoLength = 0
  self.ownerId = projectile.sourceEntity()
  self.aimPosition = mcontroller.position()
  self.rotation = 0
  self.shiftHeld = false
  self.latestYoyoId = nil

  --Constants
  self.forceReturnDistance = self.maxDistance + 3
  self.durationBeforeReturnable = 0.15

  message.setHandler("updateProjectile", function(_, _, aimPosition, fireMode, shiftHeld, latestYoyoId)
    self.aimPosition = aimPosition
    self.fireMode = fireMode
    self.shiftHeld = shiftHeld
    self.latestYoyoId = latestYoyoId
    return entity.id()
  end)

  if yoyoExtra then yoyoExtra:init() end
end

function update(dt)
	if yoyoExtra then
		yoyoExtra:update(dt)
		if self.shiftHeld and self.useShift then
			yoyoExtra:shiftHeld()
		end
	end

	self.yoyoTime = self.yoyoTime + (1 * dt)
	self.yoyoLength = world.magnitude(mcontroller.position(), self.ownerPos)
	self.ownerPos = world.entityPosition(self.ownerId)

	if self.yoyoTime >= self.maxYoyoTime or self.yoyoLength > self.forceReturnDistance or self.fireMode == "none" then
		returnYoyo()
	end

	world.debugPoly(debugCircle(self.maxDistance, 32, self.ownerPos), {255, 255, 0})
	world.debugPoly(debugCircle(world.magnitude(mcontroller.position(), self.ownerPos), 32, self.ownerPos), {0, 255, 0})
	world.debugText("%s/%s", self.yoyoLength, self.maxDistance, self.aimPosition, {0, 255, 0})
	world.debugText("latestYoyoId = %s", self.latestYoyoId and self.latestYoyoId or "none", vec2.sub(self.aimPosition, {0, 1}), {0, 255, 0})

	if self.ownerId and world.entityExists(self.ownerId) then
		if self.aimPosition then
			if self.yoyoTime > self.durationBeforeReturnable and self.returning then
				--Returning behavior
				controlTo(self.ownerPos, self.yoyoSpeed * 2, 650)

				if world.lineTileCollision(mcontroller.position(), self.ownerPos, {"Block", "Dynamic", "Null"}) then
					mcontroller.applyParameters({collisionEnabled = false})
				end

				local toTarget = world.distance(self.ownerPos, mcontroller.position())
				if vec2.mag(toTarget) < self.pickupDistance and self.yoyoTime > self.durationBeforeReturnable then
					kill()
				end
			else
				--Normal behavior
				local distToPos = world.distance(mcontroller.position(), self.aimPosition)

				if self.latestYoyoId and self.latestYoyoId ~= entity.id() and world.entityExists(self.latestYoyoId) then
					world.debugPoint(world.entityPosition(self.latestYoyroId), {255, 255, 0})

					controlTo(vec2.add(world.entityPosition(self.latestYoyoId), {math.cos(self.rotation), math.sin(self.rotation)}), self.yoyoSpeed, 650, true)
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
  mcontroller.setRotation(mcontroller.rotation() + ((self.rotationSpeed * dt) * direction))
end

function controlTo(position, speed, controlForce, ignoreMaxRange)
	controlForce = 350
	local offset = world.distance(position, mcontroller.position())
	local v = vec2.sub(position, self.ownerPos)
	if not ignoreMaxRange then
		v = vec2.clampMag(v, self.maxDistance)
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
	v = vec2.clampMag(v, self.maxDistance)
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
		world.sendEntityMessage(self.ownerId, "hitEnemy", entityId)
	end
end

function returnYoyo()
	if self.dieOnReturn then
		kill()
	else
		self.returning = true
	end
end

function kill()
	projectile.die()
end

--Helper functions
function vec2.length(vector)
	return math.sqrt(vec2.dot(vector, vector))
end

function vec2.clampMag(vector, maxLength)
	if vec2.length(vector) > maxLength then
		vector = vec2.norm(vector)
		vector = vec2.mul(vector, maxLength)
	end
	return vector
end

function debugCircle(radius, points, center)
	local poly = {}
	center = center or {0, 0}
	for i = 0, points - 1 do
		local angle = (i / points) * math.pi * 2
		table.insert(poly, vec2.add(center, vec2.withAngle(angle, radius)))
	end
	return poly
end
