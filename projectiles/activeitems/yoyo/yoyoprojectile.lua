require "/scripts/vec2.lua"

function init()
  self.returning = config.getParameter("returning", false)
  self.controlMovement = config.getParameter("controlMovement")
  self.pickupDistance = config.getParameter("pickupDistance")
  self.timeToLive = config.getParameter("timeToLive")
  self.speed = config.getParameter("speed")
  self.shortSpeedMultiplier = config.getParameter("shortSpeedMultiplier")
  self.midSpeedMultiplier = config.getParameter("midSpeedMultiplier")
  self.farSpeedMultiplier = config.getParameter("farSpeedMultiplier")
  self.timeBeforeNoCollide = config.getParameter("timeBeforeNoCollide")
  self.ownerId = projectile.sourceEntity()

  self.hoverMaxDistance = config.getParameter("hoverMaxDistance")
  self.hoverTime = config.getParameter("hoverTime")
  self.clickTimer = 0
  self.isTooFar = false
  self.isWayTooFar = false

  self.initialPosition = mcontroller.position()
  self.aimPosition = config.getParameter("ownerAimPosition")
  self.hoverDistance = math.min(self.hoverMaxDistance, world.magnitude(self.initialPosition, self.aimPosition))
  self.leftClicking = true
  message.setHandler("updateProjectile", function(_, _, aimPosition)
      self.aimPosition = aimPosition
      return entity.id()
    end)
  message.setHandler("updateHolding", function(_, _, hoverTime)
      self.hoverTime = hoverTime
	  self.holdingClick = true
      return entity.id()
    end)
  message.setHandler("notClicking", function(_, _, isClicking)
      self.isClicking = isClicking
      return entity.id()
    end)
  message.setHandler("tooFar", function(_, _, tooFar)
      self.isTooFar = tooFar
      return entity.id()
    end)
  message.setHandler("wayTooFar", function(_, _, wayTooFar)
      self.isWayTooFar = wayTooFar
      return entity.id()
    end)
  message.setHandler("ownerPos", function(_, _, ownerPosition)
      self.ownerPos = ownerPosition
      return entity.id()
    end)
  message.setHandler("leftClicking", function(_, _, leftClicking)
      self.leftClicking = leftClicking
      return entity.id()
    end)
  self.hoverPosition = vec2.add(vec2.mul(vec2.norm(mcontroller.velocity()), self.hoverDistance), self.initialPosition)
end

function update(dt)
sb.logInfo(tostring(self.leftClicking))
  if self.ownerId and world.entityExists(self.ownerId) then
    if not self.returning then
      if self.hoverTimer then
		if not self.isTooFar then
		controlTo(self.aimPosition, 1)
		end
        self.hoverTimer = math.max(0, self.hoverTimer - dt)
      end

	  if self.isClicking == false then
		if self.hoverTimer then
			self.returning = true
		else
		end
	  end
	  
	  if self.isTooFar == true then
		controlTo(self.ownerPos, 0.5)
		self.isTooFar = false
	  end
	  if self.isWayTooFar == true then
		controlTo(self.ownerPos, 100)
		self.isWayTooFar = false
	  end
      if self.hoverTimer == 0 then
        self.returning = true
      elseif self.hoverTimer then
        --mcontroller.approachVelocity({0,0}, 1000)
      else
        local distanceToHover = self.hoverDistance - world.magnitude(mcontroller.position(), self.initialPosition)
        if distanceToHover < 0.5 then
          self.hoverTimer = self.hoverTime
		  self.newX = mcontroller.xVelocity() / 2
		  self.newY = mcontroller.yVelocity() / 2
          mcontroller.setVelocity({self.newX,self.newY})
          --mcontroller.setPosition(self.hoverPosition)
        elseif distanceToHover < 5 then
          mcontroller.approachVelocity({0,0}, 300)
        end
      end
    else
      mcontroller.applyParameters({collisionEnabled=false})
      local toTarget = world.distance(world.entityPosition(self.ownerId), mcontroller.position())
      if vec2.mag(toTarget) < self.pickupDistance then
        projectile.die()
      else
        mcontroller.setVelocity(vec2.mul(vec2.norm(toTarget), self.speed))
      end
    end
  else
    projectile.die()
  end
    
  if self.leftClicking == true then
	self.clickTimer = self.clickTimer + 1
  else
	self.clickTimer = 0
  end
    world.debugText(tostring(self.isWayTooFar), self.aimPosition, {255, 255, 255, 255})

  --world.debugText(self.clickTimer, self.aimPosition, {255, 255, 255, 255})

  
  if mcontroller.isColliding() then
	if self.clickTimer >= self.timeBeforeNoCollide then

	else
		self.returning = true
	end
  end
  
  local cursorRange = world.distance(self.aimPosition, mcontroller.position())
  if self.holdingClick == true then
	self.holdingClick = false
	if vec2.mag(cursorRange) < 2.5 then
		controlTo(self.aimPosition, self.shortSpeedMultiplier)
	else
	end
  
  end
  
  if self.holdingClick == true then
	self.holdingClick = false
	if vec2.mag(cursorRange) < 5 then
		controlTo(self.aimPosition, self.midSpeedMultiplier)
	else
	end
  
  end
  if self.holdingClick == true then
	self.holdingClick = false
	if vec2.mag(cursorRange) < 8 then
		controlTo(self.aimPosition, self.farSpeedMultiplier)
	else
	end
  
  end
  
  if self.returning then
	mcontroller.setRotation(mcontroller.rotation() + (32 * dt))
  else
	mcontroller.setRotation(mcontroller.rotation() - (32 * dt))
  end
end

function controlTo(position, speedMult)
  local offset = world.distance(position, mcontroller.position())
  mcontroller.approachVelocity(vec2.mul(vec2.norm(offset), (self.controlMovement.maxSpeed * speedMult)), self.controlMovement.controlForce)
end

function projectileIds()
  return {entity.id()}
end
