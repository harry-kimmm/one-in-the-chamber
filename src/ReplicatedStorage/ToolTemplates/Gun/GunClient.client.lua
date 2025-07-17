local tool       = script.Parent
assert(tool:IsA("Tool"), "[GunClient] must be a child of a Tool")

local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local Debris     = game:GetService("Debris")
local RunService = game:GetService("RunService")

local fireEvent  = RS.GameRemotes:WaitForChild("FireBullet")
local player     = Players.LocalPlayer
local mouse      = player:GetMouse()
local ammoVal    = player:WaitForChild("Ammo")

local fxFolder       = RS:WaitForChild("Effects")
local muzzleEffects  = fxFolder:WaitForChild("MuzzleFlash")
local beamTemplate   = fxFolder:WaitForChild("BeamTracer")

local handle           = tool:WaitForChild("Handle")
local muzzleAttachment = handle:WaitForChild("MuzzleAttachment")
local shootSound       = handle:WaitForChild("ShootSound")

local MAX_RANGE     = 500
local SMOOTH_FACTOR = 0.2

local torso, shoulder, origC0, aimConn
local camera = workspace.CurrentCamera

local function updateArmAim()
	if not (torso and shoulder and origC0) then return end

	-- get camera look in torso-local space
	local look      = camera.CFrame.LookVector
	local localLook = torso.CFrame:VectorToObjectSpace(look)

	-- compute pitch (positive when looking up)
	local pitch = math.atan2(
		localLook.Y,
		math.sqrt(localLook.X*localLook.X + localLook.Z*localLook.Z)
	)

	----------------------------------------------------------------------------
	-- BUILD targetC0 by uncommenting *exactly one* of the following options:
	----------------------------------------------------------------------------

	-- 1) Rotate around X-axis (usually correct for forward/back tilt):
	-- local targetC0 = origC0 * CFrame.Angles(  pitch, 0, 0)  -- positive pitch tilts forward
	-- local targetC0 = origC0 * CFrame.Angles(- pitch, 0, 0)  -- negative pitch tilts forward

	-- 2) Rotate around Y-axis (usually twists arm; unlikely what you want):
	-- local targetC0 = origC0 * CFrame.Angles(0,  pitch, 0)
	-- local targetC0 = origC0 * CFrame.Angles(0, -pitch, 0)

	-- 3) Rotate around Z-axis (roll; can sometimes map to forward tilt):
	-- local targetC0 = origC0 * CFrame.Angles(0, 0,  pitch)
	-- local targetC0 = origC0 * CFrame.Angles(0, 0, -pitch)

	----------------------------------------------------------------------------
	-- (Example: using X-axis with positive pitch)
	----------------------------------------------------------------------------
	-- local targetC0 = origC0 * CFrame.Angles( pitch, 0, 0)

	----------------------------------------------------------------------------

	-- smoothly lerp toward that tilt
	shoulder.C0 = shoulder.C0:Lerp(targetC0, SMOOTH_FACTOR)
end

tool.Equipped:Connect(function()
	local char = player.Character or player.CharacterAdded:Wait()
	torso    = char:WaitForChild("Torso")
	shoulder = torso:WaitForChild("Right Shoulder")
	if shoulder then
		origC0 = shoulder.C0
		aimConn = RunService.RenderStepped:Connect(updateArmAim)
	end
end)

tool.Unequipped:Connect(function()
	if aimConn then aimConn:Disconnect() end
	if shoulder and origC0 then
		shoulder.C0 = origC0
	end
end)

tool.Activated:Connect(function()
	if ammoVal.Value <= 0 then return end
	shootSound:Play()

	-- muzzle flash
	for _, e in ipairs(muzzleEffects:GetChildren()) do
		if e:IsA("ParticleEmitter") then
			local em = e:Clone()
			em.Parent = muzzleAttachment
			em:Emit(1)
			Debris:AddItem(em, em.Lifetime.Max)
		end
	end

	-- beam tracer
	local origin    = muzzleAttachment.WorldPosition
	local targetPos = mouse.Hit.Position
	local dir       = (targetPos - origin).Unit

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
	-- no-op
end)
