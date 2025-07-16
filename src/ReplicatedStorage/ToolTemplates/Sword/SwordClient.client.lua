-- ToolTemplates/YourSwordTool/SwordClient (LocalScript)

local tool         = script.Parent
assert(tool and tool:IsA("Tool"), "[SwordClient] must be child of a Tool")

local Players      = game:GetService("Players")
local Debris       = game:GetService("Debris")
local player       = Players.LocalPlayer
local remotes      = game:GetService("ReplicatedStorage"):WaitForChild("GameRemotes")
local attackRemote = remotes:WaitForChild("MeleeAttack")
local resultRemote = remotes:WaitForChild("MeleeResult")

-- Two Animation objects under this script named Swing1 and Swing2
local swings = {
	script:WaitForChild("Swing1"),
	script:WaitForChild("Swing2"),
}
local nextAnim = 1

local canAttack = true
local COOLDOWN  = 0.25

tool.Activated:Connect(function()
	if not canAttack then return end
	canAttack = false

	-- play swing animation
	local char = player.Character
	if char then
		local hum = char:FindFirstChild("Humanoid")
		if hum then
			local animObj = swings[nextAnim]
			local track   = hum:LoadAnimation(animObj)
			track:Play()
			nextAnim = nextAnim % #swings + 1
		end
	end

	-- notify the server
	attackRemote:FireServer()

	-- cooldown reset
	delay(COOLDOWN, function()
		canAttack = true
	end)
end)

-- On a hit, server tells us to lunge
resultRemote.OnClientEvent:Connect(function(shouldLunge)
	if shouldLunge then
		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1e5, 0, 1e5)
		bv.Velocity = root.CFrame.LookVector * 80
		bv.Parent   = root
		Debris:AddItem(bv, 0.2)
	end
end)
