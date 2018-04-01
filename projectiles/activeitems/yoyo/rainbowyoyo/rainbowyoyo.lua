yoyoExtra = {}

function yoyoExtra:init()
  self.emitTimer = 0
end

function yoyoExtra:update(dt)
  self.emitTimer = self.emitTimer +1

  local dirs = {
    9,
    -9
  }

  if self.emitTimer > 40 then
    world.spawnProjectile("rainbowyoyotrail", world.entityPosition(projectile.sourceEntity()), entity.id(), {0, dirs[math.random(#dirs)]})
    self.emitTimer = 0
  end
end

function yoyoExtra:hit(entityId)

end