-- StarterPlayerScripts/SpeedController.lua
local controllers = {}
local SpeedController = {}
SpeedController.__index = SpeedController
function SpeedController.new(humanoid, baseSpeed, sprintMult, swordMult)
	local self = setmetatable({}, SpeedController)
	self.hum = humanoid
	self.baseSpeed = baseSpeed
	self.sprintMult = sprintMult or 1.5
	self.swordMult = swordMult or 1.1
	self.isSprint = false
	self.isSword = false
	self:Update()
	return self
end
function SpeedController.Get(humanoid, baseSpeed, sprintMult, swordMult)
	if controllers[humanoid] then
		return controllers[humanoid]
	end
	local ctrl = SpeedController.new(humanoid, baseSpeed, sprintMult, swordMult)
	controllers[humanoid] = ctrl
	return ctrl
end
function SpeedController:SetSprint(on)
	self.isSprint = on
	self:Update()
end
function SpeedController:SetSword(on)
	self.isSword = on
	self:Update()
end
function SpeedController:Update()
	local s = self.baseSpeed
	if self.isSprint then s = s * self.sprintMult end
	if self.isSword then s = s * self.swordMult end
	self.hum.WalkSpeed = s
end
return SpeedController
