local tool            = script.Parent
local Players         = game:GetService("Players")
local RS              = game:GetService("ReplicatedStorage")
local Debris          = game:GetService("Debris")
local ContentProvider = game:GetService("ContentProvider")
local TweenService    = game:GetService("TweenService")
local remotes         = RS:WaitForChild("GameRemotes")
local meleeAttack     = remotes:WaitForChild("MeleeAttack")
local grantEvent      = remotes:WaitForChild("GrantBullet")
local player          = Players.LocalPlayer
local swings          = {
	tool:WaitForChild("Swing1"),
	tool:WaitForChild("Swing2"),
	tool:WaitForChild("Swing3")
}
local equipAnim       = tool:WaitForChild("EquipAnimation")
local EQUIP_DELAY     = 0.3
local COOLDOWN        = 0.30
local HIT_DELAY       = 0.3
local BOX_DISTANCE    = -5
local BOX_SIZE        = Vector3.new(5,5,6)
local BOX_TIME        = 0.2
local STOP_TWEEN_TIME = 0.1
local RESUME_TWEEN_TIME = 0.1
local REDUCE_FACTOR   = 0.5
local nextIndex       = 1
local canAttack       = false
local isAttacking     = false
local origSpeed
local speedOverrideConn
ContentProvider:PreloadAsync{
	swings[1].AnimationId,
	swings[2].AnimationId,
	swings[3].AnimationId,
	equipAnim.AnimationId
}
local swingTracks = {}
local equipTrack
local function setupTracks(char)
	local humanoid = char:WaitForChild("Humanoid")
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	for i, animObj in ipairs(swings) do
		if not swingTracks[i] then
			local t = animator:LoadAnimation(animObj)
			t.Priority = Enum.AnimationPriority.Action
			t.Looped   = false
			swingTracks[i] = t
		end
	end
	if not equipTrack then
		equipTrack = animator:LoadAnimation(equipAnim)
		equipTrack.Priority = Enum.AnimationPriority.Action
		equipTrack.Looped   = false
	end
end
player.CharacterAdded:Connect(setupTracks)
if player.Character then setupTracks(player.Character) end
tool.Equipped:Connect(function()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum  = char:WaitForChild("Humanoid")
	origSpeed     = hum.WalkSpeed
	hum.WalkSpeed = origSpeed * 1.75
	canAttack = false
	equipTrack:Play()
	delay(EQUIP_DELAY, function() canAttack = true end)
end)
tool.Unequipped:Connect(function()
	isAttacking = false
	canAttack   = false
	if equipTrack.IsPlaying then equipTrack:Stop(0) end
	for _, t in ipairs(swingTracks) do
		if t.IsPlaying then t:Stop(0) end
	end
	if speedOverrideConn then speedOverrideConn:Disconnect() speedOverrideConn = nil end
	if origSpeed then
		local char = player.Character
		if char then char:FindFirstChild("Humanoid").WalkSpeed = origSpeed end
	end
end)
tool.Activated:Connect(function()
	if not canAttack then return end
	canAttack   = false
	isAttacking = true
	local char = player.Character
	local hum  = char and char:FindFirstChild("Humanoid")
	local boostedSpeed = origSpeed and origSpeed * 1.75
	local reducedSpeed = boostedSpeed and boostedSpeed * REDUCE_FACTOR
	if hum and reducedSpeed then
		TweenService:Create(
			hum,
			TweenInfo.new(STOP_TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{WalkSpeed = reducedSpeed}
		):Play()
		speedOverrideConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if not canAttack then hum.WalkSpeed = reducedSpeed end
		end)
	end
	local track = swingTracks[nextIndex]
	if track then track:Play(0.1, 1, 2) end
	nextIndex = (nextIndex % #swingTracks) + 1
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
		wait(COOLDOWN)
		if hum and boostedSpeed then
			TweenService:Create(
				hum,
				TweenInfo.new(RESUME_TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
				{WalkSpeed = boostedSpeed}
			):Play()
		end
		if speedOverrideConn then speedOverrideConn:Disconnect() speedOverrideConn = nil end
		canAttack = true
	end)
end)
grantEvent.OnClientEvent:Connect(function() end)
