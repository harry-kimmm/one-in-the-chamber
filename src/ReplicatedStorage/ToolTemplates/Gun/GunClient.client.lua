-- StarterPack/Gun/GunClient.lua

local tool        = script.Parent
local Players     = game:GetService("Players")
local RS          = game:GetService("ReplicatedStorage")
local Debris      = game:GetService("Debris")
local RunService  = game:GetService("RunService")
local TweenService= game:GetService("TweenService")

local fireEvent   = RS.GameRemotes:WaitForChild("FireBullet")
local grantEvent  = RS.GameRemotes:WaitForChild("GrantBullet")
local player      = Players.LocalPlayer
local Mouse       = player:GetMouse()
local ammoVal     = player:WaitForChild("Ammo")

local fxFolder       = RS:WaitForChild("Effects")
local muzzleEffects  = fxFolder:WaitForChild("MuzzleFlash")
local beamTemplate   = fxFolder:WaitForChild("BeamTracer")

local handle           = tool:WaitForChild("Handle")
local muzzleAttachment = handle:WaitForChild("MuzzleAttachment")
local shootSound       = handle:WaitForChild("ShootSound")

local MAX_RANGE        = 500
local CORRECTION_OFFSET= math.pi/2

-- arm‑aim state
local torso, shoulder, origC0
local AIM_STEP_NAME = "ArmAim"

local function updateArmAim()
	if not (torso and shoulder and origC0) then return end

	local worldPos = (torso.CFrame * origC0).Position
	local target   = Mouse.Hit.Position
	local lookCF   = CFrame.new(worldPos, target)
	local pitch, _, _ = lookCF:ToOrientation()

	local corrected = pitch + CORRECTION_OFFSET
	shoulder.C0 = origC0 * CFrame.Angles(0, 0, corrected)
end

tool.Equipped:Connect(function()
	local char = player.Character or player.CharacterAdded:Wait()
	torso    = char:WaitForChild("Torso")
	shoulder = torso:FindFirstChild("Right Shoulder")
	if not shoulder then return end

	origC0 = shoulder.C0
	RunService:BindToRenderStep(AIM_STEP_NAME, Enum.RenderPriority.Camera.Value, updateArmAim)
end)

tool.Unequipped:Connect(function()
	RunService:UnbindFromRenderStep(AIM_STEP_NAME)
	if shoulder and origC0 then
		shoulder.C0 = origC0
	end
end)

tool.Activated:Connect(function()
	if ammoVal.Value <= 0 then return end
	shootSound:Play()
	fireEvent:FireServer(Mouse.Hit.Position)

	for _, e in ipairs(muzzleEffects:GetChildren()) do
		if e:IsA("ParticleEmitter") then
			local em = e:Clone()
			em.Parent = muzzleAttachment
			em:Emit(1)
			Debris:AddItem(em, em.Lifetime.Max)
		end
	end

	local origin = muzzleAttachment.WorldPosition
	local dir    = (Mouse.Hit.Position - origin).Unit
	local beam   = beamTemplate:Clone()
	beam.Parent  = workspace
	beam.Attachment0.WorldPosition = origin
	beam.Attachment1.WorldPosition = origin + dir * MAX_RANGE
	beam:FindFirstChildOfClass("Beam").Enabled = true
	Debris:AddItem(beam, 0.2)
end)

grantEvent.OnClientEvent:Connect(function()
	-- no‑op
end)
