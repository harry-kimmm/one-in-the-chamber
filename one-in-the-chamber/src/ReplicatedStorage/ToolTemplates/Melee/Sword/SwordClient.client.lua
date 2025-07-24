local tool            = script.Parent
local Players         = game:GetService("Players")
local RS              = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local TweenService    = game:GetService("TweenService")
local remotes         = RS:WaitForChild("GameRemotes")
local meleeAttack     = remotes:WaitForChild("MeleeAttack")
local player          = Players.LocalPlayer

local swings = {
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
local REDUCE_FACTOR   = 0.5

-- preload
ContentProvider:PreloadAsync{
	swings[1].AnimationId,
	swings[2].AnimationId,
	swings[3].AnimationId,
	equipAnim.AnimationId
}

local swingTracks, equipTrack = {}, nil
local humanoid, speedCtrl
local canAttack, isAttacking = false, false
local nextIndex = 1

local SpeedController = require(game.StarterPlayer.StarterPlayerScripts.SpeedController)

-- setup animations & speed controller
local function setup(char)
	humanoid = char:WaitForChild("Humanoid")
	local animator = humanoid:FindFirstChildOfClass("Animator")
		or Instance.new("Animator", humanoid)

	for i, animObj in ipairs(swings) do
		if not swingTracks[i] then
			local t = animator:LoadAnimation(animObj)
			t.Priority = Enum.AnimationPriority.Action
			swingTracks[i] = t
		end
	end

	if not equipTrack then
		equipTrack = animator:LoadAnimation(equipAnim)
		equipTrack.Priority = Enum.AnimationPriority.Action
	end

	-- now hook speed controller
	speedCtrl = SpeedController.new(humanoid, humanoid.WalkSpeed)
end

player.CharacterAdded:Connect(setup)
if player.Character then setup(player.Character) end

tool.Equipped:Connect(function()
	canAttack = false
	equipTrack:Play()
	-- turn on sword buff
	speedCtrl:SetSword(true)
	delay(EQUIP_DELAY, function()
		canAttack = true
	end)
end)

tool.Unequipped:Connect(function()
	isAttacking = false
	canAttack   = false
	if equipTrack.IsPlaying then equipTrack:Stop(0) end
	for _, t in ipairs(swingTracks) do
		if t.IsPlaying then t:Stop(0) end
	end
	-- turn off sword buff
	speedCtrl:SetSword(false)
end)

tool.Activated:Connect(function()
	if not canAttack then return end
	canAttack   = false
	isAttacking = true

	local track = swingTracks[nextIndex]
	if track then track:Play(0.1, 1, 2) end
	nextIndex = (nextIndex % #swingTracks) + 1

	spawn(function()
		wait(HIT_DELAY)
		if isAttacking then
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local cf = hrp.CFrame * CFrame.new(0,0,BOX_DISTANCE)
				meleeAttack:FireServer(cf, BOX_SIZE)
			end
		end
		isAttacking = false
		wait(COOLDOWN)
		canAttack = true
	end)
end)
