local UserInputService = game:GetService("UserInputService")
local player            = game:GetService("Players").LocalPlayer
local MAX_JUMPS         = 2
local ANIMATION_ID      = "rbxassetid://131389514455185" 

local function setupCharacter(char)
	local humanoid  = char:WaitForChild("Humanoid")
	local jumpCount = 0
	local anim      = Instance.new("Animation")
	anim.AnimationId = ANIMATION_ID
	local track     = humanoid:LoadAnimation(anim)

	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed
			or newState == Enum.HumanoidStateType.Running then
			jumpCount = 0
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.Space and jumpCount < MAX_JUMPS then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			jumpCount += 1
			if jumpCount == MAX_JUMPS then
				track:Play(0, 1, 2)
			end
		end
	end)
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then
	setupCharacter(player.Character)
end
