local Player=game.Players.LocalPlayer
local Char=Player.Character or Player.CharacterAdded:Wait()
local RunService=game:GetService("RunService")
RunService.Heartbeat:Connect(function()
	if Char:FindFirstChild("PBSTUN") or Char:FindFirstChild("noJump") then
		Char.Humanoid.UseJumpPower=true
		Char.Humanoid.JumpPower=0
	else
		Char.Humanoid.JumpPower=50
	end
end)
