local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Cam = workspace.CurrentCamera
local player = game.Players.LocalPlayer

local defaultFOV = 70
local defaultSpeed = 16
local sprintMult = 24.5 / defaultSpeed

local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local runsVal = char:FindFirstChild("Running") or Instance.new("BoolValue", char)
runsVal.Name = "Running"
runsVal.Value = false

local SpeedController = require(player:WaitForChild("PlayerScripts"):WaitForChild("SpeedController"))
local speedCtrl = SpeedController.Get(hum, defaultSpeed, sprintMult)

local runAnim = hum:LoadAnimation(script:WaitForChild("Run"))
runAnim.Priority = Enum.AnimationPriority.Movement

local shiftHeld = false
local isSprinting = false
local wantsSprint = false  -- <— NEW: mobile toggle state

hum:SetAttribute("BlockSprint", false)

local function startSprint()
	if isSprinting or hum:GetAttribute("BlockSprint") then return end
	runAnim:Play()
	runsVal.Value = true
	TweenService:Create(Cam, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { FieldOfView = defaultFOV + 15 }):Play()
	speedCtrl:SetSprint(true)
	isSprinting = true
end

local function stopSprint()
	if not isSprinting then return end
	runAnim:Stop()
	runsVal.Value = false
	TweenService:Create(Cam, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { FieldOfView = defaultFOV }):Play()
	speedCtrl:SetSprint(false)
	hum:SetAttribute("BlockSprint", false)
	isSprinting = false
end

hum.AttributeChanged:Connect(function(attr)
	if attr == "BlockSprint" and hum:GetAttribute("BlockSprint") and isSprinting then
		stopSprint()
	end
end)

player.CharacterAdded:Connect(function(c)
	char = c
	hum = c:WaitForChild("Humanoid")
	speedCtrl = SpeedController.Get(hum, defaultSpeed, sprintMult)
	runsVal = c:FindFirstChild("Running") or Instance.new("BoolValue", c)
	runsVal.Name = "Running"
	runsVal.Value = false
	isSprinting = false
	-- keep wantsSprint as-is across respawns so mobile toggle “sticks”
	runAnim = hum:LoadAnimation(script:WaitForChild("Run"))
	runAnim.Priority = Enum.AnimationPriority.Movement
	TweenService:Create(Cam, TweenInfo.new(0.1), { FieldOfView = defaultFOV }):Play()
end)

-- Action binding with proper mobile toggle semantics
local function SprintAction(_, inputState)
	local touchOnly = UIS.TouchEnabled and not UIS.KeyboardEnabled and not UIS.MouseEnabled
	if touchOnly then
		if inputState == Enum.UserInputState.Begin then
			-- Toggle desired sprint state
			wantsSprint = not wantsSprint
			if not wantsSprint then
				-- Turning off: immediately stop if currently sprinting
				if isSprinting then stopSprint() end
			else
				-- Turning on: if already moving and not blocked, start now
				if hum.MoveDirection.Magnitude > 0 and not hum:GetAttribute("BlockSprint") then
					startSprint()
				end
			end
		end
		return Enum.ContextActionResult.Sink
	else
		-- PC/Console = hold-to-sprint
		if inputState == Enum.UserInputState.Begin then
			shiftHeld = true
			if hum.MoveDirection.Magnitude > 0 and not hum:GetAttribute("BlockSprint") then
				startSprint()
			end
		elseif inputState == Enum.UserInputState.End then
			shiftHeld = false
			stopSprint()
		end
		return Enum.ContextActionResult.Sink
	end
end

CAS:BindAction("Sprint", SprintAction, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
CAS:SetTitle("Sprint", "Sprint")
CAS:SetPosition("Sprint", UDim2.new(0.08, 0, 0.78, 0))

hum.Running:Connect(function(speed)
	local blocked = hum:GetAttribute("BlockSprint")
	if (shiftHeld or wantsSprint) and speed > 0 and not blocked then
		if not isSprinting then startSprint() end
	else
		if isSprinting and (speed <= 0 or blocked or (not shiftHeld and not wantsSprint)) then
			stopSprint()
		end
	end
end)
