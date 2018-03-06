require "/scripts/vec2.lua"

function init()
  self.position = mcontroller.position()
  self.id = nil
  self.time = 0
  message.setHandler("updatePosition", function(_, _, position, id)
    self.position = position
    self.id = id
    return entity.id()
  end)
end

function update(dt)
  self.time = self.time +1
  if self.id and world.entityExists(self.id) then
    mcontroller.setPosition(self.position)
  else
    if self.time > 20 then
      projectile.die()
    end
  end
end
