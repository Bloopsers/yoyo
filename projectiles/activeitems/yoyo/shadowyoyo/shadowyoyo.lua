yoyoExtra = {}

function yoyoExtra:init()
  self.basePower = config.getParameter("power")
  self.stacks = 0
  self.damagePerStack = config.getParameter("damagePerStack")
  self.maxStacks = config.getParameter("maxStacks")
  self.maxHitTimer = config.getParameter("maxHitTimer")
  self.hitTimer = 0
  self.damageUpAction = config.getParameter("damageUpAction")
end

function yoyoExtra:update(dt)
  if self.stacks >= 1 then
    self.hitTimer = self.hitTimer + (1 * dt)
  end
  if self.hitTimer > self.maxHitTimer then
    -- reset power if we havent hit anything for x seconds
    self.stacks = 0
    self.hitTimer = 0
    textParticle("x0")
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
      self.stacks = self.stacks +1
      textParticle("x"..self.stacks)
      projectile.processAction(self.damageUpAction)
      projectile.setPower(self.basePower + (self.damagePerStack * self.stacks))
    end
  end
end
