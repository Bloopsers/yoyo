function init()
	local healthMax = world.entityHealth(entity.id())[2]

	-- dont want to confuse boss enemies etc
	if healthMax >= 500 then
		effect.expire()
	end

	if math.random(1, config.getParameter("chance", 1)) ~= 1 then
		effect.expire()
	end

	script.setUpdateDelta(0)
	local baseParameters = sb.jsonMerge({runSpeed = 0, walkSpeed = 0}, mcontroller.baseParameters())
	mcontroller.controlParameters({runSpeed=-baseParameters.runSpeed, walkSpeed=-baseParameters.walkSpeed})

	animator.setParticleEmitterOffsetRegion("confused", mcontroller.boundBox())
	animator.burstParticleEmitter("confused")
	effect.setParentDirectives("?flipx")
end
