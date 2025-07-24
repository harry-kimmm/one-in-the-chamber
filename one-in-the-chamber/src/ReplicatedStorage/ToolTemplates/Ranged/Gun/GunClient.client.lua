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
local Mouse = player:GetMouse()
local ammoVal = player:WaitForChild("Ammo")

local fxFolder = RS:WaitForChild("Effects")
local muzzleEffects = fxFolder:WaitForChild("MuzzleFlash")
local handle = tool:WaitForChild("Handle")
local muzzleAttachment = handle:WaitForChild("MuzzleAttachment")
local shootSound = handle:WaitForChild("ShootSound")

local MAX_RANGE = 500
local equipAnim = tool:WaitForChild("EquipAnimation")
local fireAnim = tool:WaitForChild("FireAnimation")
local aimAnim = tool:WaitForChild("AimAnimation")

local equipTrack, fireTrack, aimTrack
local humanoid, originalWalkSpeed, originalJumpPower
local camera = workspace.CurrentCamera
local originalFOV = camera.FieldOfView
local aiming = false

ContentProvider:PreloadAsync({ equipAnim, fireAnim, aimAnim })

local function setupTracks(char)
	humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	originalWalkSpeed = humanoid.WalkSpeed
	originalJumpPower = humanoid.JumpPower
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	if not equipTrack or equipTrack.Parent ~= animator then
		equipTrack = animator:LoadAnimation(equipAnim)
		equipTrack.Priority = Enum.AnimationPriority.Action
	end
	if not fireTrack or fireTrack.Parent ~= animator then
		fireTrack = animator:LoadAnimation(fireAnim)
		fireTrack.Priority = Enum.AnimationPriority.Action
	end
	if not aimTrack or aimTrack.Parent ~= animator then
		aimTrack = animator:LoadAnimation(aimAnim)
		aimTrack.Priority = Enum.AnimationPriority.Action
		aimTrack.Looped = true
	end
end

player.CharacterAdded:Connect(setupTracks)
if player.Character then
	setupTracks(player.Character)
end

tool.Equipped:Connect(function()
	tool.Enabled = false
	if equipTrack then equipTrack:Play(0.1, 1, 1.5) end
	delay(0.3, function() tool.Enabled = true end)
end)

tool.Unequipped:Connect(function()
	if equipTrack and equipTrack.IsPlaying then equipTrack:Stop(0) end
	if fireTrack and fireTrack.IsPlaying then fireTrack:Stop(0) end
	if aimTrack and aimTrack.IsPlaying then aimTrack:Stop(0) end
	if aiming then
		humanoid.WalkSpeed = originalWalkSpeed
		humanoid.JumpPower = originalJumpPower
		TweenService:Create(camera, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			FieldOfView = originalFOV
		}):Play()
		aiming = false
	end
	tool.Enabled = true
end)

tool.Activated:Connect(function()
	if not tool.Enabled or ammoVal.Value <= 0 then return end
	if fireTrack then fireTrack:Play() end
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
end)

local function beginAim()
	if aiming or not humanoid then return end
	if humanoid.MoveDirection.Magnitude > 0 then return end
	aiming = true
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	if aimTrack then aimTrack:Play() end
	TweenService:Create(camera, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FieldOfView = 30
	}):Play()
end

local function endAim()
	if not aiming or not humanoid then return end
	aiming = false
	humanoid.WalkSpeed = originalWalkSpeed
	humanoid.JumpPower = originalJumpPower
	if aimTrack and aimTrack.IsPlaying then aimTrack:Stop(0.2) end
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
