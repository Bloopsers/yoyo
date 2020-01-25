require "/scripts/util.lua"
require "/scripts/yoyoutils.lua"
require "/scripts/vec2.lua"
require "/scripts/activeitem/stances.lua"

function addProjectile(id, type, parameters, counterweight)
    local ropeDefaults = {
        line = {},
        color = {255, 255, 255, 255},
        rainbow = false,
        hue = 0,
        hueRange = {0, 360},
        hueCycleSpeed = 1,
        fullbright = false
    }
    self.projectiles[id] = {
        type = type,
        parameters = parameters,
        id = nil,
        position = {0, 0},
        counterweight = counterweight ~= nil and counterweight or false,
        rope = sb.jsonMerge(ropeDefaults, config.getParameter("rope"))
    }
end

function init()
    self.projectiles = {}
    addProjectile("yoyo", config.getParameter("projectileType"), config.getParameter("projectileParameters"))

    --Yoyo properties
    self.counterweights = config.getParameter("counterweights", {})
    self.fireOffset = config.getParameter("fireOffset")
    self.maxLength = config.getParameter("maxLength", 5) + config.getParameter("extraLength", 0)

    self.lastFireMode = "none"
    self.fireMode = "none"
    self.aimAngle = 0
    self.facingDirection = 0
    self.activeCounterweight = 1
    self.shiftHeld = false
    self.dualWielding = false
    self.dualWieldingAnchorId = nil
    self.active = false

    self.projectiles.yoyo.parameters.power = self.projectiles.yoyo.parameters.power * root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1))

    for index, counterweight in pairs(self.counterweights) do
        counterweight.projectileParameters.power = self.projectiles.yoyo.parameters.power * (counterweight.projectileParameters.powerScale or 0)
        addProjectile("counterWeight" .. index, counterweight.projectileType, counterweight.projectileParameters, index)
    end

    message.setHandler("yoyos:hitEnemy", function(_, _, entityId) spawnCounterweights() end)
    message.setHandler("yoyos:syncState/" .. activeItem.hand(), function(_, _, id, returning)
        for index, projectile in pairs(self.projectiles) do
            sb.logInfo(sb.print(projectile))
            if world.entityExists(projectile.id) and not projectile.counterweight then
                world.callScriptedEntity(projectile.id, "syncAnchorState", returning)
            end
        end
    end)

    initStances()
    setStance("idle")
end

function uninit() cancel() end

function setAnchorId(id)
    self.dualWieldingAnchorId = id
end

function update(dt, fireMode, shiftHeld, moves)
    activeItem.setScriptedAnimationParameter("projectiles", self.projectiles)

    local tags = activeItem.hand() == "alt" and player.primaryHandItemTags() or player.altHandItemTags()
    if not config.getParameter("twoHanded", true) then
        if tags then
            if contains(tags, "yoyo") then
                self.dualWielding = true
            end
        end
    end

    self.fireMode = fireMode
    self.shiftHeld = shiftHeld
    self.aimAngle, self.facingDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
    activeItem.setFacingDirection(self.facingDirection)

    if self.active then
        trackProjectiles()
        updateRopes()
    end

    if self.stanceName == "idle" then
        if (fireMode == "primary" or fireMode == "alt") and not (self.lastFireMode == "primary" or self.lastFireMode == "alt") then
            setStance("windup")
        end
    end

    self.lastFireMode = fireMode

    if self.stanceName == "throw" then
        if not self.projectiles.yoyo.id or not world.entityExists(self.projectiles.yoyo.id) then
            setStance("precatch")
            animator.playSound("catch")
        end
    end

    updateStance(dt)
    updateAim()
end

function updateRopes()
    for index, projectile in pairs(self.projectiles) do
        local rope = projectile.rope
        if rope.rainbow then
            rope.hue = rope.hue + (rope.hueCycleSpeed * 2)
            if rope.hue > rope.hueRange[2] then
                rope.hue = rope.hueRange[1]
            end
            rope.color = yoyoUtils.hslToRgb(rope.hue, 170, 170, 255)
        end
        projectile.rope = rope
    end
end

function trackProjectiles()
    for index, projectile in pairs(self.projectiles) do
        if projectile.id and world.entityExists(projectile.id) then
            projectile.position = world.entityPosition(projectile.id)
        else
            -- cycle counterweight after the projectile dies
            if projectile.counterweight and (projectile.id and not world.entityExists(projectile.id)) then
                projectile.id = nil
                self.activeCounterweight = self.activeCounterweight + 1
                if self.activeCounterweight > #self.counterweights then
                    self.activeCounterweight = 1
                end
            end
        end
    end
    if not anyYoyoProjectile() then
        cancel()
    else
        if self.dualWielding and not self.dualWieldingAnchorId then
            self.dualWieldingAnchorId = self.projectiles.yoyo.id
            activeItem.callOtherHandScript("setAnchorId", self.dualWieldingAnchorId)
        end

        world.sendEntityMessage(self.projectiles.yoyo.id, "updateProjectile", activeItem.ownerAimPosition(), self.fireMode, self.shiftHeld, self.dualWieldingAnchorId)
    end
end

function spawnCounterweights()
    local currentCounterweight = self.projectiles["counterWeight" .. self.activeCounterweight]
    if currentCounterweight and not currentCounterweight.id then
        local proj = self.projectiles["counterWeight" .. self.activeCounterweight]
        self.projectiles["counterWeight" .. self.activeCounterweight].id = world.spawnProjectile(proj.type, mcontroller.position(), activeItem.ownerEntityId(), {0, 0}, false, proj.parameters)
    end
end

function fire()
    local parameters = copy(self.projectiles.yoyo.parameters)
    parameters.powerMultiplier = activeItem.ownerPowerMultiplier()
    parameters.ownerAimPosition = activeItem.ownerAimPosition()
    parameters.maxDistance = self.maxLength

    self.projectiles.yoyo.id = world.spawnProjectile(self.projectiles.yoyo.type, firePosition(), activeItem.ownerEntityId(), aimVector(), false, parameters)
    if not self.dualWieldingAnchorId and self.dualWielding then
        self.dualWieldingAnchorId = self.projectiles.yoyo.id
        activeItem.callOtherHandScript("setAnchorId", self.dualWieldingAnchorId)
    end

    self.active = true
    animator.playSound("throw")
end

function cancel()
    self.active = false

    for index, projectile in pairs(self.projectiles) do
        if projectile.id and world.entityExists(projectile.id) then
            world.callScriptedEntity(projectile.id, "kill")
        end
    end

    if self.dualWielding then
        self.dualWieldingAnchorId = nil
        activeItem.callOtherHandScript("setAnchorId", nil)
    end
end

function anyYoyoProjectile()
    for index, projectile in pairs(self.projectiles) do
        if not projectile.counterweight then
            if projectile.id and world.entityExists(projectile.id) then
                return projectile
            end
        end
    end
end

function firePosition()
    local entityPos = mcontroller.position()
    local barrelOffset = activeItem.handPosition(self.fireOffset)
    local barrelPosition = vec2.add(entityPos, barrelOffset)
    local collidePoint = world.lineCollision(entityPos, barrelPosition)
    if collidePoint then
        return vec2.add(entityPos, vec2.mul(barrelOffset, vec2.mag(barrelOffset) - 0.5))
    else
        return barrelPosition
    end
end
