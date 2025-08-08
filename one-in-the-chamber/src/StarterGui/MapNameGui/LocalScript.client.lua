local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameRemotes       = ReplicatedStorage:WaitForChild("GameRemotes")
local beginRound        = GameRemotes:WaitForChild("BeginRound")
local endRound          = GameRemotes:WaitForChild("EndRound")
local label             = script.Parent:WaitForChild("MapNameLabel")

label.Visible = false

beginRound.OnClientEvent:Connect(function(mapName)
	label.Text    = "Map: "..mapName
	label.Visible = true
end)

endRound.OnClientEvent:Connect(function()
	label.Visible = false
end)
