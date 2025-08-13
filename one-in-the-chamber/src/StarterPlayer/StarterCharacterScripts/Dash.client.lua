local CAS = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
while not Char.Parent do Char.AncestryChanged:Wait() end
local Hum = Char:WaitForChild("Humanoid")
local HumRP = Char:WaitForChild("HumanoidRootPart")

local RollFrontAnim = Hum:LoadAnimation(script:WaitForChild("RollFront"))
local BackRollAnim  = Hum:LoadAnimation(script:WaitForChild("BackRoll"))
local LeftRollAnim  = Hum:LoadAnimation(script:WaitForChild("LeftRoll"))
local RightRollAnim = Hum:LoadAnimation(script:WaitForChild("RightRoll"))
for _, track in ipairs({RollFrontAnim, BackRollAnim, LeftRollAnim, RightRollAnim}) do
	track.Priority = Enum.AnimationPriority.Action
end

local DASH_MULTIPLIER = 2
local DASH_DURATION = 0.15
local START_TWEEN_TIME = 0.05
local END_TWEEN_TIME = 0.1

local DashDebounce = false

local function getMeleeTool()
	for _, t in ipairs(Player.Backpack:GetChildren()) do
		if t:IsA("Tool") and t:FindFirstChild("SwordClient") then return t end
	end
	for _, t in ipairs(Char:GetChildren()) do
		if t:IsA("Tool") and t:FindFirstChild("SwordClient") then return t end
	end
end

local function playDirectionalRoll()
	local move = Hum.MoveDirection
	if move.Magnitude < 0.1 then RollFrontAnim:Play(); return end
	local f = HumRP.CFrame.LookVector
	local r = HumRP.CFrame.RightVector
	local forwardDot = move:Dot(f)
	local rightDot = move:Dot(r)
	if math.abs(forwardDot) >= math.abs(rightDot) then
		if forwardDot >= 0 then RollFrontAnim:Play() else BackRollAnim:Play() end
	else
		if rightDot >= 0 then RightRollAnim:Play() else LeftRollAnim:Play() end
	end
end

local function DashAction(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
	if DashDebounce then return Enum.ContextActionResult.Sink end
	if Char:FindFirstChild("PBSTUN") or Char:FindFirstChild("noJump") or HumRP:FindFirstChildOfClass("BodyVelocity") then
		return Enum.ContextActionResult.Sink
	end

	DashDebounce = true
	task.delay(1, function() DashDebounce = false end)

	local meleeTool = getMeleeTool()
	if meleeTool then meleeTool.Enabled = false end

	playDirectionalRoll()

	local originalSpeed = Hum.WalkSpeed
	local dashSpeed = originalSpeed * DASH_MULTIPLIER

	TweenService:Create(Hum, TweenInfo.new(START_TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {WalkSpeed = dashSpeed}):Play()
	task.delay(DASH_DURATION, function()
		TweenService:Create(Hum, TweenInfo.new(END_TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {WalkSpeed = originalSpeed}):Play()
		if meleeTool then meleeTool.Enabled = true end
	end)

	return Enum.ContextActionResult.Sink
end

CAS:BindAction("Dash", DashAction, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
CAS:SetTitle("Dash", "Dash")
CAS:SetPosition("Dash", UDim2.new(0.88, 0, 0.78, 0)) 
