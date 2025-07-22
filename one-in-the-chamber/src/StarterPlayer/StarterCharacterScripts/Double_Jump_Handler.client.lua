local player = game.Players.LocalPlayer
local character = player.Character
repeat wait()
	character = player.Character
until character

local hum = character:WaitForChild("Humanoid")
local flip = hum:LoadAnimation(script.Jump_Animation)

local doubleJumped = false
local canDoubleJump = false
local jumpMultiplier = 1.5
local defaultJump = hum.JumpPower

local cooldown = false

game:GetService("UserInputService").JumpRequest:Connect(function()
	
	if canDoubleJump == true and doubleJumped == false and cooldown == false then
		hum.JumpPower = defaultJump * jumpMultiplier
		doubleJumped = true
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
		flip:Play()
		wait(flip.Length)
		flip:Stop()
	end
	
end)

hum.StateChanged:Connect(function(oldState, newState)
	
	if newState == Enum.HumanoidStateType.Landed then
		hum.JumpPower = defaultJump
		doubleJumped = false
		canDoubleJump = false
		hum.JumpPower = defaultJump * jumpMultiplier
		if flip.IsPlaying then
			hum:ChangeState(Enum.HumanoidStateType.Ragdoll)
		end
	elseif newState == Enum.HumanoidStateType.Freefall then
		wait(0.2)
		canDoubleJump = true
	elseif newState == Enum.HumanoidStateType.Ragdoll then
		wait(2)
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	
end)