-- StarterCharacterScripts/dashing/Dash.lua

local UIS           = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local Player        = game.Players.LocalPlayer
local Char          = Player.Character or Player.CharacterAdded:Wait()
while not Char.Parent do Char.AncestryChanged:Wait() end
local Hum           = Char:WaitForChild("Humanoid")
local HumRP         = Char:WaitForChild("HumanoidRootPart")

-- dash animations
local RollFrontAnim = Hum:LoadAnimation(script:WaitForChild("RollFront"))
local BackRollAnim  = Hum:LoadAnimation(script:WaitForChild("BackRoll"))
local LeftRollAnim  = Hum:LoadAnimation(script:WaitForChild("RightRoll"))
local RightRollAnim = Hum:LoadAnimation(script:WaitForChild("LeftRoll"))
for _, track in ipairs({RollFrontAnim, BackRollAnim, LeftRollAnim, RightRollAnim}) do
	track.Priority = Enum.AnimationPriority.Action
end

-- configurable dash parameters
local DASH_MULTIPLIER   = 2   -- how many times faster than normal
local DASH_DURATION     = 0.15  -- how long the boost lasts
local START_TWEEN_TIME  = 0.05  -- how quickly to ramp up speed
local END_TWEEN_TIME    = 0.1   -- how quickly to ramp down speed

local DashDebounce      = false
local CanDoAnything     = true
local WKey, AKey, SKey, DKey = false, false, false, false

-- helper: find your sword tool (so we can disable melee during dash)
local function getMeleeTool()
	for _, t in ipairs(Player.Backpack:GetChildren()) do
		if t:IsA("Tool") and t:FindFirstChild("SwordClient") then
			return t
		end
	end
	for _, t in ipairs(Char:GetChildren()) do
		if t:IsA("Tool") and t:FindFirstChild("SwordClient") then
			return t
		end
	end
end

UIS.InputBegan:Connect(function(input, processed)
	-- don't dash if input was consumed, you're stunned, or sliding (detected by a BodyVelocity on HumRP)
	if processed 
		or Char:FindFirstChild("PBSTUN") 
		or Char:FindFirstChild("noJump")
		or HumRP:FindFirstChildOfClass("BodyVelocity") then
		return
	end

	if input.KeyCode == Enum.KeyCode.Q and not DashDebounce and CanDoAnything then
		DashDebounce = true
		CanDoAnything = false
		delay(0.3, function() CanDoAnything = true end)
		delay(1,   function() DashDebounce = false end)

		local meleeTool = getMeleeTool()
		if meleeTool then meleeTool.Enabled = false end

		-- play the correct dash animation
		if WKey then
			RollFrontAnim:Play()
		elseif SKey then
			BackRollAnim:Play()
		elseif DKey then
			LeftRollAnim:Play()
		elseif AKey then
			RightRollAnim:Play()
		end

		-- speed boost
		local originalSpeed = Hum.WalkSpeed
		local dashSpeed     = originalSpeed * DASH_MULTIPLIER

		-- ramp up
		TweenService:Create(
			Hum,
			TweenInfo.new(START_TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ WalkSpeed = dashSpeed }
		):Play()

		-- after dash duration, ramp back down & re‑enable melee
		delay(DASH_DURATION, function()
			TweenService:Create(
				Hum,
				TweenInfo.new(END_TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
				{ WalkSpeed = originalSpeed }
			):Play()

			if meleeTool then meleeTool.Enabled = true end
		end)
	end
end)

RunService.RenderStepped:Connect(function()
	WKey = UIS:IsKeyDown(Enum.KeyCode.W)
	AKey = UIS:IsKeyDown(Enum.KeyCode.A)
	SKey = UIS:IsKeyDown(Enum.KeyCode.S)
	DKey = UIS:IsKeyDown(Enum.KeyCode.D)
end)
