local tool      = script.Parent
assert(tool:IsA("Tool"), "[GunClient] must be a child of a Tool")

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")
local Debris    = game:GetService("Debris")

local fireEvent  = RS.GameRemotes:WaitForChild("FireBullet")
local grantEvent = RS.GameRemotes:WaitForChild("GrantBullet")

local player    = Players.LocalPlayer
local mouse     = player:GetMouse()

local ammoVal   = player:WaitForChild("Ammo")

local fxFolder        = RS:WaitForChild("Effects")
local muzzleEffects   = fxFolder:WaitForChild("MuzzleFlash")   
local beamTemplate    = fxFolder:WaitForChild("BeamTracer") 

local handle           = tool:WaitForChild("Handle")
local muzzleAttachment = handle:WaitForChild("MuzzleAttachment")
local shootSound       = handle:WaitForChild("ShootSound")

local MAX_RANGE = 500

tool.Activated:Connect(function()
	if ammoVal.Value <= 0 then
		return
	end

	shootSound:Play()

	local origin    = muzzleAttachment.WorldPosition
	local targetPos = mouse.Hit.Position
	local dir       = (targetPos - origin).Unit

	for _, emitterTemplate in ipairs(muzzleEffects:GetChildren()) do
		if emitterTemplate:IsA("ParticleEmitter") then
			local emitter = emitterTemplate:Clone()
			emitter.Parent = muzzleAttachment
			emitter:Emit(1)
			Debris:AddItem(emitter, emitter.Lifetime.Max)
		end
	end

	
	local beamClone = beamTemplate:Clone()
	beamClone.Parent = workspace

	local a0 = beamClone:FindFirstChild("Attachment0")
	local a1 = beamClone:FindFirstChild("Attachment1")
	if a0 then a0.WorldPosition = origin end
	if a1 then a1.WorldPosition = origin + dir * MAX_RANGE end

	local beam = beamClone:FindFirstChildOfClass("Beam")
	if beam then beam.Enabled = true end

	Debris:AddItem(beamClone, 0.2)

	fireEvent:FireServer(targetPos)
end)

grantEvent.OnClientEvent:Connect(function()

end)
