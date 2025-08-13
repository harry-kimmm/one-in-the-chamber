local CAS = game:GetService("ContextActionService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

local slideTrack = hum:LoadAnimation(script:WaitForChild("SlideAnim"))
slideTrack.Priority = Enum.AnimationPriority.Action

local sliding = false

local function getMeleeTool()
	for _, tool in ipairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool:FindFirstChild("SwordClient") then return tool end
	end
	for _, tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") and tool:FindFirstChild("SwordClient") then return tool end
	end
end

local function SlideAction(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
	if sliding then return Enum.ContextActionResult.Sink end
	sliding = true

	local meleeTool = getMeleeTool()
	if meleeTool then meleeTool.Enabled = false end

	slideTrack:Play()

	local v = Instance.new("BodyVelocity")
	v.MaxForce = Vector3.new(1,0,1) * 30000
	v.Velocity = root.CFrame.LookVector * 100
	v.Parent = root

	for _ = 1, 8 do
		task.wait(0.1)
		v.Velocity *= 0.7
	end

	slideTrack:Stop()
	v:Destroy()
	if meleeTool then meleeTool.Enabled = true end

	task.delay(3, function() sliding = false end)
	return Enum.ContextActionResult.Sink
end

CAS:BindAction("Slide", SlideAction, true, Enum.KeyCode.C, Enum.KeyCode.ButtonX)
CAS:SetTitle("Slide", "Slide")
CAS:SetPosition("Slide", UDim2.new(0.88, 0, 0.62, 0)) -- above Dash on mobile
