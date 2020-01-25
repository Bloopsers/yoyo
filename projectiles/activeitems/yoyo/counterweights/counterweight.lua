require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/yoyoutils.lua"

function init()
	mcontroller.applyParameters({
		gravityEnabled = false
	})
	mcontroller.applyParameters(config.getParameter("movementSettings", {}))

	--Counterweight properties
	self.maxDistance = config.getParameter("rotateRadius", 8)
	self.speed = config.getParameter("rotateSpeed", 60)
	self.maxTime = config.getParameter("maxTime")
	self.dieOnReturn = config.getParameter("dieOnReturn")
	self.forceDisableCollision = config.getParameter("forceDisableCollision", false)

	self.returning = false
	self.time = 0
	self.lastColliding = false
	self.angle = math.random(360)
	self.ownerId = projectile.sourceEntity()

	--Constants
	self.pickupDistance = 1
	self.rotateSpeed = 0.02
end

function update(dt)
	self.ownerPos = world.entityPosition(self.ownerId)
	world.debugPoly(yoyoUtils.circlePoly(self.maxDistance, 32, self.ownerPos), {0, 0, 255})

	self.time = self.time + (1 * dt)

	if self.time > self.maxTime or (not self.forceDisableCollision and world.pointTileCollision(mcontroller.position(), {"Block", "Dynamic", "Null"})) then
		returnCounterweight()
	end

	if self.returning then
		controlTo2(self.ownerPos, self.speed, 350)

		if world.magnitude(mcontroller.position(), self.ownerPos) < self.pickupDistance then
			projectile.die()
		end
	else
		local pos = predictNextPosition()
		if not self.forceDisableCollision and world.pointTileCollision(pos, {"Block", "Dynamic", "Null"}) and not self.lastColliding then
			self.rotateSpeed = -self.rotateSpeed
			pos = predictNextPosition(2)
		end
		controlTo(pos, self.speed, 350)
		self.lastColliding = world.pointTileCollision(pos, {"Block", "Dynamic", "Null"})
	end

	mcontroller.setRotation(self.angle)
end

function returnCounterweight()
	if self.dieOnReturn then
		projectile.die()
	else
		self.returning = true
		mcontroller.applyParameters({collisionEnabled = false})
	end
end

function kill()
	projectile.die()
end

function predictNextPosition(mod)
	mod = mod or 1
	self.angle = self.angle + (self.rotateSpeed * mod)
	local offset = vec2.mul({math.sin(self.angle), math.cos(self.angle)}, self.maxDistance)
	local pos = vec2.add(vec2.rotate(offset, self.angle * self.maxDistance), self.ownerPos)
	return pos
end
  
function hit(entityId)
	self.rotateSpeed = -self.rotateSpeed
end
  
function controlTo(position, speed, controlForce)
	local offset = world.distance(position, mcontroller.position())
	local v = yoyoUtils.clampMag(vec2.sub(position, self.ownerPos), self.maxDistance)
	local pos = vec2.approach(mcontroller.position(), vec2.add(self.ownerPos, v), speed / 60)

	if (not self.forceDisableCollision and world.lineTileCollision(mcontroller.position(), pos, {"Block", "Dynamic", "Null"})) or self.returning then
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

