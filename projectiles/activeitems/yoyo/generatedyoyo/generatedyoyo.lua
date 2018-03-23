function yoyoExtra:init()
  displayAction = {
    action = "particle",
    specification = {
      type = "textured",
      image = config.getParameter("yoyoImage"),
      timeToLive = 0.01,
      layer = "front",
      flippable = true,
      rotation = 0
    }
  }
end

function yoyoExtra:update(dt)
  displayAction.specification.rotation = self.rotation * 60
  projectile.processAction(displayAction)
end
