local UIS=game:GetService("UserInputService")
local Tween=game:GetService("TweenService")
local Cam=workspace.CurrentCamera
local player=game.Players.LocalPlayer
local char=player.Character or player.CharacterAdded:Wait()
local hum=char:WaitForChild("Humanoid")
local runsVal=char:WaitForChild("Running")
local runAnim=hum:LoadAnimation(script:WaitForChild("Run"))
runAnim.Priority = Enum.AnimationPriority.Movement
local defaultFOV=70
local defaultSpeed=16
local sprintSpeed=24.5
local shiftHeld=false
local isSprinting=false

local function startSprint()
	runAnim:Play()
	hum.WalkSpeed=sprintSpeed
	runsVal.Value=true
	Tween:Create(Cam,TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{FieldOfView=defaultFOV+15}):Play()
	isSprinting=true
end

local function stopSprint()
	runAnim:Stop()
	hum.WalkSpeed=defaultSpeed
	runsVal.Value=false
	Tween:Create(Cam,TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{FieldOfView=defaultFOV}):Play()
	isSprinting=false
end

UIS.InputBegan:Connect(function(input,processed)
	if processed then return end
	if input.KeyCode==Enum.KeyCode.LeftShift then
		shiftHeld=true
		if hum.MoveDirection.Magnitude>0 then
			startSprint()
		end
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode==Enum.KeyCode.LeftShift then
		shiftHeld=false
		stopSprint()
	end
end)

hum.Running:Connect(function(speed)
	if shiftHeld and speed>0 then
		if not isSprinting then
			startSprint()
		end
	elseif isSprinting then
		stopSprint()
	end
end)
