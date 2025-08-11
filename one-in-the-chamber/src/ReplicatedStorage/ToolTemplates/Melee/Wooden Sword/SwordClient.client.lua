local tool = script.Parent
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local remotes = RS:WaitForChild("GameRemotes")
local meleeAttack = remotes:WaitForChild("MeleeAttack")

local player = Players.LocalPlayer
local swings = {
	tool:WaitForChild("Swing1"),
	tool:WaitForChild("Swing2"),
	tool:WaitForChild("Swing3")
}
local swingSound = tool:FindFirstChild("SwingSound")
local equipAnim = tool:WaitForChild("EquipAnimation")

local EQUIP_DELAY = 0.3
local COOLDOWN = 0.5
local BOX_DISTANCE = -5
local BOX_SIZE = Vector3.new(5,5,6)

ContentProvider:PreloadAsync{
	swings[1].AnimationId,
	swings[2].AnimationId,
	swings[3].AnimationId,
	equipAnim.AnimationId
}

local swingTracks = {}
local equipTrack
local humanoid
local speedCtrl
local canAttack = false
local nextIndex = 1

local SpeedController = require(player:WaitForChild("PlayerScripts"):WaitForChild("SpeedController"))

local function setup(char)
	humanoid = char:WaitForChild("Humanoid")
	humanoid:SetAttribute("BlockSprint", false)
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
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
	speedCtrl = SpeedController.Get(humanoid, humanoid.WalkSpeed)
end

player.CharacterAdded:Connect(setup)
if player.Character then setup(player.Character) end

tool.Equipped:Connect(function()
	canAttack = false
	equipTrack:Play()
	speedCtrl:SetSword(true)
	task.delay(EQUIP_DELAY, function() canAttack = true end)
end)

tool.Unequipped:Connect(function()
	canAttack = false
	if equipTrack.IsPlaying then equipTrack:Stop(0) end
	for _, t in ipairs(swingTracks) do
		if t.IsPlaying then t:Stop(0) end
	end
	speedCtrl:SetSword(false)
	if humanoid then humanoid:SetAttribute("BlockSprint", false) end
end)

tool.Activated:Connect(function()
	if not canAttack or not humanoid then return end
	canAttack = false
	if speedCtrl then speedCtrl:SetSprint(false) end
	humanoid:SetAttribute("BlockSprint", true)

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		local regionCFrame = hrp.CFrame * CFrame.new(0,0,BOX_DISTANCE)
		meleeAttack:FireServer(regionCFrame, BOX_SIZE)
	end

	local track = swingTracks[nextIndex]
	if track then
		track:Play(0.1, 1, 2)
		if swingSound then swingSound:Play() end
	end
	nextIndex = (nextIndex % #swingTracks) + 1

	task.delay(COOLDOWN, function()
		if humanoid then humanoid:SetAttribute("BlockSprint", false) end
		canAttack = true
	end)
end)
