-- StarterGui/RunningMain.lua
local UIS = game:GetService("UserInputService")
local Tween = game:GetService("TweenService")
local Cam = workspace.CurrentCamera
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local runsVal = char:WaitForChild("Running")
local runAnim = hum:LoadAnimation(script:WaitForChild("Run"))
runAnim.Priority = Enum.AnimationPriority.Movement
local defaultFOV = 70
local defaultSpeed = 16
local sprintMult = 24.5 / defaultSpeed
local shiftHeld = false
local isSprinting = false
local SpeedController = require(player:WaitForChild("PlayerScripts"):WaitForChild("SpeedController"))
local speedCtrl = SpeedController.Get(hum, defaultSpeed, sprintMult)
hum:SetAttribute("BlockSprint", false)

hum.AttributeChanged:Connect(function(attr)
	if attr == "BlockSprint" and hum:GetAttribute("BlockSprint") and isSprinting then
		runAnim:Stop()
		runsVal.Value = false
		speedCtrl:SetSprint(false)
		isSprinting = false
	end
end)

local function startSprint()
	runAnim:Play()
	runsVal.Value = true
	Tween:Create(Cam, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		FieldOfView = defaultFOV + 15
	}):Play()
	speedCtrl:SetSprint(true)
	isSprinting = true
end

local function stopSprint()
	runAnim:Stop()
	runsVal.Value = false
	Tween:Create(Cam, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		FieldOfView = defaultFOV
	}):Play()
	speedCtrl:SetSprint(false)
	hum:SetAttribute("BlockSprint", false)
	isSprinting = false
end

UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		shiftHeld = true
		if hum.MoveDirection.Magnitude > 0 and not hum:GetAttribute("BlockSprint") then
			startSprint()
		end
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		shiftHeld = false
		stopSprint()
	end
end)

hum.Running:Connect(function(speed)
	if shiftHeld and speed > 0 and not hum:GetAttribute("BlockSprint") then
		if not isSprinting then
			startSprint()
		end
	elseif isSprinting then
		stopSprint()
	end
end)
