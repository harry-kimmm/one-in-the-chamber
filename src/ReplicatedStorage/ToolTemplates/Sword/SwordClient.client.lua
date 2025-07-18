-- SwordClient.lua

local tool         = script.Parent
local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local Debris       = game:GetService("Debris")

local remotes      = RS:WaitForChild("GameRemotes")
local attackRemote = remotes:WaitForChild("MeleeAttack")
local grantEvent   = remotes:WaitForChild("GrantBullet")

local player   = Players.LocalPlayer
local swings   = { script:WaitForChild("Swing1"), script:WaitForChild("Swing2") }
local nextAnim = 1

local canAttack = true
local COOLDOWN  = 1.25    -- seconds between swings
local HIT_RANGE = 5       -- your melee distance

tool.Equipped:Connect(function()
	local hum = player.Character and player.Character:FindFirstChild("Humanoid")
	if hum then
		hum.WalkSpeed = (hum.WalkSpeed or 16) * 1.3
	end
end)
tool.Unequipped:Connect(function()
	local hum = player.Character and player.Character:FindFirstChild("Humanoid")
	if hum and origSpeed then
		hum.WalkSpeed = origSpeed
	end
end)

tool.Activated:Connect(function()
	if not canAttack then return end
	canAttack = false

	-- play swing anim
	local hum = player.Character and player.Character:FindFirstChild("Humanoid")
	if hum then
		local track = hum:LoadAnimation(swings[nextAnim])
		track:Play()
		nextAnim = nextAnim % #swings + 1
	end

	-- tell server
	attackRemote:FireServer()

	-- always show a red neon box at max reach
	local char = player.Character
	if char then
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			local tipPos = root.Position + root.CFrame.LookVector * HIT_RANGE
			local box = Instance.new("Part")
			box.Size         = Vector3.new(1, 1, 1)
			box.CFrame       = CFrame.new(tipPos)
			box.Anchored     = true
			box.CanCollide   = false
			box.Material     = Enum.Material.Neon
			box.Color        = Color3.new(1, 0, 0)
			box.Transparency = 0.5
			box.Parent       = workspace

			Debris:AddItem(box, 0.2)
		end
	end

	-- reset cooldown
	delay(COOLDOWN, function()
		canAttack = true
	end)
end)

grantEvent.OnClientEvent:Connect(function()
	-- optional: flash UI or play sound
end)
