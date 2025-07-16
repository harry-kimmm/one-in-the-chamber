local runService = game:GetService("RunService")
local plr = game.Players.LocalPlayer
repeat wait() until plr.Character
local char = plr.Character
local hum = char:WaitForChild("Humanoid")
local walking = false

hum.Running:Connect(function(speed)
	walking = speed > hum.WalkSpeed/2
end)

runService.Heartbeat:Connect(function()
end)
