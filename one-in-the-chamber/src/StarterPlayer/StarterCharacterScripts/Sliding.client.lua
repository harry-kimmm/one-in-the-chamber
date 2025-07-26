-- StarterCharacterScripts/Sliding.lua
local UIS       = game:GetService("UserInputService")
local char      = script.Parent
local anim      = Instance.new("Animation")
anim.AnimationId = script:WaitForChild("SlideAnim").AnimationId
local key       = Enum.KeyCode.C
local ok        = true

local function getMeleeTool()
	local player = game.Players.LocalPlayer
	for _, tool in ipairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool:FindFirstChild("SwordClient") then
			return tool
		end
	end
	for _, tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") and tool:FindFirstChild("SwordClient") then
			return tool
		end
	end
end

UIS.InputBegan:Connect(function(input, processed)
	if processed or not ok then return end
	if input.KeyCode == key then
		ok = false
		local meleeTool = getMeleeTool()
		if meleeTool then meleeTool.Enabled = false end

		local track = char:WaitForChild("Humanoid"):LoadAnimation(anim)
		track.Priority = Enum.AnimationPriority.Action
		track:Play()

		local v = Instance.new("BodyVelocity")
		v.MaxForce = Vector3.new(1,0,1) * 30000
		v.Velocity = char.HumanoidRootPart.CFrame.LookVector * 100
		v.Parent   = char.HumanoidRootPart

		for i = 1, 8 do
			wait(0.1)
			v.Velocity = v.Velocity * 0.7
		end

		track:Stop()
		v:Destroy()

		if meleeTool then meleeTool.Enabled = true end

		wait(1)
		ok = true
	end
end)
