yoyoExtra = {}

function yoyoExtra:init()
  self.basePower = config.getParameter("power")
  self.stacks = 0
  self.maxStacks = config.getParameter("maxStacks")
  self.maxHitTimer = config.getParameter("maxHitTimer")
  self.hitTimer = 0
  
  self.soundAction = config.getParameter("soundAction")
  self.soundAction2 = config.getParameter("soundAction2")
  self.soundAction3 = config.getParameter("soundAction3")
  --self.damageAction1 = config.getParameter("damageAction1")
  self.damageAction2 = config.getParameter("damageAction2")
  self.damageAction3 = config.getParameter("damageAction3")
end

function yoyoExtra:update(dt)
  if self.stacks >= 1 then
    self.hitTimer = self.hitTimer + (1 * dt)
  end
  if self.hitTimer > self.maxHitTimer then
    -- reset power if we havent hit anything for x seconds
	if self.stacks == 3 then
	  projectile.processAction(self.soundAction3)
	else
	  projectile.processAction(self.soundAction)
	end
    self.stacks = 0
    self.hitTimer = 0
    projectile.setPower(self.basePower)
    textParticle("^#7924ab;x"..self.stacks)
    projectile.setPower(self.basePower)
  end
end

function textParticle(text)
  local action = {
    action = "particle",
    specification = {
      type = "text",
      size = 0.6,
      text = text,
      fullbright = true,
      initialVelocity = {0, 3.0},
      finalVelocity = {0, 4.0},
      approach = {0, 30},
      position = {0, 0},
      timeToLive = 1.0,
      layer = "front",
      destructionAction = "shrink",
      destructionTime = 0.5,
      variance = {
        initialVelocity = {0, 4.0}
      },
      flippable = false
    }
  }
  projectile.processAction(action)
end

function yoyoExtra:hit(entityId)
  -- make sure we're hitting an enemy and not some bushes or something
  if world.entityDamageTeam(entityId).type == "enemy" then
    self.hitTimer = 0
    if self.stacks < self.maxStacks then
	  projectile.processAction(self.soundAction)
      self.stacks = self.stacks +1
	  textParticle("^#7924ab;x"..self.stacks)
    elseif self.stacks >= self.maxStacks then
	  self.stacks = 0
      projectile.setPower(self.basePower)
	  --projectile.processAction(self.damageAction1)
	  projectile.processAction(self.damageAction2)
      projectile.processAction(self.damageAction3)
	end
	if self.stacks == 3 then
	  projectile.processAction(self.soundAction2)
      projectile.setPower(0)
	end
  end
end
