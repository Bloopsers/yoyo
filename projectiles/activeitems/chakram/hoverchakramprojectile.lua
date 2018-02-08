require "/scripts/vec2.lua"

function init()
  self.returning = config.getParameter("returning", false)
  self.returnOnHit = config.getParameter("returnOnHit", false)
  self.controlMovement = config.getParameter("controlMovement")
  self.pickupDistance = config.getParameter("pickupDistance")
  self.timeToLive = config.getParameter("timeToLive")
  self.speed = config.getParameter("speed")
  self.ownerId = projectile.sourceEntity()

  self.hoverMaxDistance = config.getParameter("hoverMaxDistance")
  self.hoverTime = config.getParameter("hoverTime")

  self.initialPosition = mcontroller.position()
  self.aimPosition = config.getParameter("ownerAimPosition")
  self.hoverDistance = math.min(self.hoverMaxDistance, world.magnitude(self.initialPosition, self.aimPosition))
  message.setHandler("updateProjectile", function(_, _, aimPosition)
      self.aimPosition = aimPosition
      return entity.id()
    end)
  message.setHandler("updateHolding", function(_, _, hoverTime)
      self.hoverTime = hoverTime
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
  message.setHandler("ownerPos", function(_, _, ownerPosition)
      self.ownerPos = ownerPosition
      return entity.id()
    end)
  self.hoverPosition = vec2.add(vec2.mul(vec2.norm(mcontroller.velocity()), self.hoverDistance), self.initialPosition)
end

function update(dt)
  if self.ownerId and world.entityExists(self.ownerId) then
    if not self.returning then
      if self.hoverTimer then
		if not self.isTooFar then
		controlTo(self.aimPosition)
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
		controlTo(self.ownerPos)
		self.isTooFar = false
	  end
      if mcontroller.isColliding() or self.hoverTimer == 0 then
        self.returning = true
      elseif self.hoverTimer then
        --mcontroller.approachVelocity({0,0}, 1000)
      else
        local distanceToHover = self.hoverDistance - world.magnitude(mcontroller.position(), self.initialPosition)
        if distanceToHover < 0.5 then
          self.hoverTimer = self.hoverTime
          mcontroller.setVelocity({0,0})
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
end

function controlTo(position)
  local offset = world.distance(position, mcontroller.position())
  mcontroller.approachVelocity(vec2.mul(vec2.norm(offset), self.controlMovement.maxSpeed), self.controlMovement.controlForce)
end

function hit(entityId)
  if self.returnOnHit then self.returning = true end
end

function projectileIds()
  return {entity.id()}
end
