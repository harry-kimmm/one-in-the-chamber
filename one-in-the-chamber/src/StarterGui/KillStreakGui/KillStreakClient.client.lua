-- KillStreakClient (LocalScript under KillStreakGui)
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local remotes = RS:WaitForChild("GameRemotes")
local KSUpd   = remotes:WaitForChild("KillStreakUpdate")

local player = Players.LocalPlayer
local gui    = player:WaitForChild("PlayerGui"):WaitForChild("KillStreakGui")
local label  = gui:WaitForChild("StreakLabel")

local notes = {}
for i = 1, 8 do
	notes[i] = gui:WaitForChild("Note"..i)
end

KSUpd.OnClientEvent:Connect(function(streak)
	if streak >= 1 then
		label.Text    = "Kill Streak: "..streak
		label.Visible = true

		local idx = math.min(streak, #notes)
		notes[idx]:Play()
	else
		label.Visible = false
	end
end)
