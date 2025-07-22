
local Player = game.Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local RunService = game:GetService("RunService")

RunService.Heartbeat:Connect(function(run)
	if Char:FindFirstChild("PBSTUN") then
		Char.Humanoid.UseJumpPower = true
		Char.Humanoid.JumpPower = 0
	
	else
		Char.Humanoid.JumpPower = 50
		
	end
	
	if Char:FindFirstChild("noJump") then
		Char.Humanoid.UseJumpPower = true
		Char.Humanoid.JumpPower = 0
	else
		Char.Humanoid.JumpPower = 50
	end
end)