local tool = script.Parent 
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local fireEvent = RS:WaitForChild("GameRemotes"):WaitForChild("FireBullet")
local grantEvent = RS:WaitForChild("GameRemotes"):WaitForChild("GrantBullet")
local player = Players.LocalPlayer
local Mouse  = player:GetMouse()
local ammoVal = player:WaitForChild("Ammo")

local fxFolder     = RS:WaitForChild("Effects")
local muzzleEffects = fxFolder:WaitForChild("RedLazerMuzzleFlash")
local beamEffects   = fxFolder:WaitForChild("RedLazerTracer")

local handle            = tool:WaitForChild("Handle")
local muzzleAttachment  = handle:WaitForChild("MuzzleAttachment")
local shootSound        = handle:WaitForChild("ShootSound")

local MAX_RANGE = 500
local equipAnim = tool:WaitForChild("EquipAnimation")
local fireAnim  = tool:WaitForChild("FireAnimation")
local aimAnim   = tool:WaitForChild("AimAnimation")

local equipTrack, fireTrack, aimTrack
local humanoid, originalWalkSpeed, originalJumpPower
local camera = workspace.CurrentCamera
local originalFOV = camera.FieldOfView
local aiming = false
local equipped = false

local canShoot = true
local SHOOT_COOLDOWN = 1 

ContentProvider:PreloadAsync({equipAnim, fireAnim, aimAnim, muzzleEffects, beamEffects})

local function setupTracks(char)
	humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	originalWalkSpeed = humanoid.WalkSpeed
	originalJumpPower  = humanoid.JumpPower
	local animator = humanoid:FindFirstChildOfClass("Animator") 
		or Instance.new("Animator", humanoid)
	equipTrack = animator:LoadAnimation(equipAnim)
	equipTrack.Priority = Enum.AnimationPriority.Action
	fireTrack = animator:LoadAnimation(fireAnim)
	fireTrack.Priority = Enum.AnimationPriority.Action
	aimTrack = animator:LoadAnimation(aimAnim)
	aimTrack.Priority = Enum.AnimationPriority.Action
	aimTrack.Looped = true
end

player.CharacterAdded:Connect(setupTracks)
if player.Character then setupTracks(player.Character) end

tool.Equipped:Connect(function()
	equipped = true
	tool.Enabled = false
	equipTrack:Play(0.1, 1, 1.5)
	delay(0.3, function() tool.Enabled = true end)
end)

tool.Unequipped:Connect(function()
	equipped = false
	equipTrack:Stop(0)
	fireTrack:Stop(0)
	aimTrack:Stop(0)
	if aiming then
		humanoid.WalkSpeed = originalWalkSpeed
		humanoid.JumpPower  = originalJumpPower
		TweenService:Create(camera, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			FieldOfView = originalFOV
		}):Play()
		aiming = false
	end
	tool.Enabled = true
end)

tool.Activated:Connect(function()
	if not tool.Enabled or ammoVal.Value <= 0 or not canShoot then return end

	canShoot = false
	delay(SHOOT_COOLDOWN, function()
		canShoot = true
	end)

	fireTrack:Play()
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

	for _, template in ipairs(beamEffects:GetChildren()) do
		if template:IsA("Beam") then
			local beam = template:Clone()
			beam.Parent = workspace      
			beam.Attachment0 = muzzleAttachment

			local dir = (Mouse.Hit.Position - muzzleAttachment.WorldPosition).Unit
			local dist = math.min(MAX_RANGE, (Mouse.Hit.Position - muzzleAttachment.WorldPosition).Magnitude)
			local endPos = muzzleAttachment.WorldPosition + dir * dist

			local endAttachment = Instance.new("Attachment")
			endAttachment.Parent = workspace
			endAttachment.WorldPosition = endPos
			beam.Attachment1 = endAttachment

			local flashTime = 0.05
			delay(flashTime, function()
				beam:Destroy()
				endAttachment:Destroy()
			end)
		end
	end
end)

local function beginAim()
	if not equipped or aiming or not humanoid then return end
	aiming = true
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	aimTrack:Play()
	TweenService:Create(camera, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FieldOfView = 30
	}):Play()
end

-- Stop aiming
local function endAim()
	if not aiming or not humanoid then return end
	aiming = false
	humanoid.WalkSpeed = originalWalkSpeed
	humanoid.JumpPower = originalJumpPower
	aimTrack:Stop(0.2)
	TweenService:Create(camera, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FieldOfView = originalFOV
	}):Play()
end

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.UserInputType == Enum.UserInputType.MouseButton2 then
		beginAim()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		endAim()
	end
end)

grantEvent.OnClientEvent:Connect(function() end)
