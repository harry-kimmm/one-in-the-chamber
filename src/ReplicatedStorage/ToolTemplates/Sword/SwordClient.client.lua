local tool            = script.Parent
local Players         = game:GetService("Players")
local RS              = game:GetService("ReplicatedStorage")
local Debris          = game:GetService("Debris")
local ContentProvider = game:GetService("ContentProvider")
local TweenService    = game:GetService("TweenService")

-- remotes
local remotes     = RS:WaitForChild("GameRemotes")
local meleeAttack = remotes:WaitForChild("MeleeAttack")
local grantEvent  = remotes:WaitForChild("GrantBullet")

local player = Players.LocalPlayer

-- Animation instances (all under the Tool)
local swings    = {
	tool:WaitForChild("Swing1"),
	tool:WaitForChild("Swing2"),
}
local equipAnim = tool:WaitForChild("EquipAnimation")

-- Tweakable parameters
local EQUIP_DELAY       = 0.3   -- seconds before you can swing after equipping
local COOLDOWN          = 0.30   -- seconds movement is reduced after a swing
local HIT_DELAY         = 0.35   -- seconds before the hit‑box spawns
local BOX_DISTANCE      = -5
local BOX_SIZE          = Vector3.new(5,5,6)
local BOX_TIME          = 0.2
local STOP_TWEEN_TIME   = 0.1    -- seconds to tween down to reduced speed
local RESUME_TWEEN_TIME = 0.1    -- seconds to tween back up to boosted speed
local REDUCE_FACTOR     = 0.5    -- fraction of boosted speed to reduce to (0.5 = 50%)

-- Internal state
local nextIndex         = 1
local canAttack         = false
local isAttacking       = false
local origSpeed
local speedOverrideConn

-- Preload animations so there's no hitch on first play
ContentProvider:PreloadAsync{
	swings[1].AnimationId,
	swings[2].AnimationId,
	equipAnim.AnimationId,
}

-- Containers for loaded AnimationTracks
local swingTracks = {}
local equipTrack

-- Load tracks onto the character’s Animator
local function setupTracks(char)
	local humanoid = char:WaitForChild("Humanoid")
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	-- Load swing tracks (Action priority, non-looped)
	for i, animObj in ipairs(swings) do
		if not swingTracks[i] then
			local t = animator:LoadAnimation(animObj)
			t.Priority = Enum.AnimationPriority.Action
			t.Looped   = false
			swingTracks[i] = t
		end
	end

	-- Load equip (draw‑sword) track
	if not equipTrack then
		equipTrack = animator:LoadAnimation(equipAnim)
		equipTrack.Priority = Enum.AnimationPriority.Action
		equipTrack.Looped   = false
	end
end

-- Whenever the character spawns, set up tracks
player.CharacterAdded:Connect(setupTracks)
if player.Character then
	setupTracks(player.Character)
end

-- On equip: play draw animation, boost speed, allow swings after EQUIP_DELAY
tool.Equipped:Connect(function()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum  = char:WaitForChild("Humanoid")

	-- Store original walk speed and boost
	origSpeed     = hum.WalkSpeed
	hum.WalkSpeed = origSpeed * 1.75

	-- Play draw animation
	canAttack = false
	if equipTrack then
		equipTrack:Play()
	end

	-- Allow attacking after fixed equip delay
	delay(EQUIP_DELAY, function()
		canAttack = true
	end)
end)

-- On unequip: stop any playing anims, reset speed, clean up
tool.Unequipped:Connect(function()
	isAttacking = false
	canAttack   = false

	if equipTrack and equipTrack.IsPlaying then
		equipTrack:Stop(0)
	end
	for _, t in ipairs(swingTracks) do
		if t and t.IsPlaying then
			t:Stop(0)
		end
	end

	if speedOverrideConn then
		speedOverrideConn:Disconnect()
		speedOverrideConn = nil
	end

	-- Restore original walk speed
	if origSpeed then
		local char = player.Character
		if char then
			local hum = char:FindFirstChild("Humanoid")
			if hum then hum.WalkSpeed = origSpeed end
		end
	end
end)

-- On click: play one swing at 2× speed, reduce movement speed, handle hit, then restore
tool.Activated:Connect(function()
	if not canAttack then return end
	canAttack   = false
	isAttacking = true

	local char = player.Character
	local hum  = char and char:FindFirstChild("Humanoid")
	local boostedSpeed = origSpeed and origSpeed * 1.75
	local reducedSpeed = boostedSpeed and boostedSpeed * REDUCE_FACTOR

	if hum and reducedSpeed then
		-- Smoothly tween WalkSpeed down to reducedSpeed
		TweenService:Create(
			hum,
			TweenInfo.new(STOP_TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ WalkSpeed = reducedSpeed }
		):Play()

		-- Clamp WalkSpeed to reducedSpeed until restore
		speedOverrideConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if not canAttack then
				hum.WalkSpeed = reducedSpeed
			end
		end)
	end

	-- Play the next swing at double speed
	local track = swingTracks[nextIndex]
	if track then
		track:Play(0.1, 1, 2)
	end
	nextIndex = (nextIndex % #swingTracks) + 1

	-- Handle hit-box spawn and restoration
	spawn(function()
		wait(HIT_DELAY)
		if isAttacking then
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local cf = hrp.CFrame * CFrame.new(0,0,BOX_DISTANCE)
				local box = Instance.new("Part")
				box.Size         = BOX_SIZE
				box.CFrame       = cf
				box.Anchored     = true
				box.CanCollide   = false
				box.Transparency = 0.5
				box.BrickColor   = BrickColor.new("Really red")
				box.Parent       = workspace
				Debris:AddItem(box, BOX_TIME)
				meleeAttack:FireServer(cf, BOX_SIZE)
			end
		end

		isAttacking = false

		-- Wait out movement lock
		wait(COOLDOWN)

		-- Restore WalkSpeed smoothly over RESUME_TWEEN_TIME
		if hum and boostedSpeed then
			TweenService:Create(
				hum,
				TweenInfo.new(RESUME_TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
				{ WalkSpeed = boostedSpeed }
			):Play()
		end

		-- Stop clamping
		if speedOverrideConn then
			speedOverrideConn:Disconnect()
			speedOverrideConn = nil
		end

		canAttack = true
	end)
end)

-- Optional: handle any client updates from grantEvent
grantEvent.OnClientEvent:Connect(function()
	-- e.g. update UI for refunded ammo/coins
end)
