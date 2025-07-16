local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local Character = script.Parent
local Humanoid = Character:WaitForChild("Humanoid")
local Mouse = Player:GetMouse()
local Camera = workspace:WaitForChild("Camera")
local Storage = ReplicatedStorage:WaitForChild("Storage")
local RunService = game:GetService("RunService")

local AnimationFolder = Storage:WaitForChild("Animations")
local CrouchAnimation = Humanoid:LoadAnimation(AnimationFolder:WaitForChild("Crouch"))

local function IsPlayerMoving()
	if Humanoid.MoveDirection.Magnitude == 0 then
	end
end

RunService.RenderStepped:Connect(IsPlayerMoving)

Mouse.KeyDown:Connect(function(Key)
	if Key == "c" then
		CrouchAnimation:Play()
		Humanoid.WalkSpeed = Humanoid.WalkSpeed/2
		Camera.CameraSubject = Character:WaitForChild("Head")
		Camera.FieldOfView = 65
		local function IsPlayerMoving()
			if Humanoid.MoveDirection.Magnitude == 0 then
				CrouchAnimation:AdjustSpeed(0)
			else
				CrouchAnimation:AdjustSpeed(1)
			end
		end
		RunService.RenderStepped:Connect(IsPlayerMoving)
		Player.CameraMinZoomDistance = 7
	end
end)

Mouse.KeyUp:Connect(function(Key)
	if Key == "c" then
		CrouchAnimation:Stop()
		Humanoid.WalkSpeed = Humanoid.WalkSpeed * 2
		Camera.FieldOfView = 70
		Camera.CameraSubject = Character:WaitForChild("Humanoid")
		Player.CameraMinZoomDistance = 0.5
	end
end)
