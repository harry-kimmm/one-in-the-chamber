-- StarterGui/RoundUI/RoundUI_Client.lua

local RS      = game:GetService("ReplicatedStorage")
local remotes = RS:WaitForChild("GameRemotes")

local screen    = script.Parent
local lobbyLbl  = screen:WaitForChild("LobbyLabel")
local roundLbl  = screen:WaitForChild("RoundLabel")
local endLbl    = screen:WaitForChild("EndLabel")

print("[RoundUI] Client script loaded")

remotes.StartLobby.OnClientEvent:Connect(function(time)
	lobbyLbl.Visible      = true
	lobbyLbl.Text         = "Intermission: " .. time
	roundLbl.Visible      = false
	endLbl.Visible        = false
end)

remotes.StartRound.OnClientEvent:Connect(function(time)
	roundLbl.Visible      = true
	roundLbl.Text         = "Round: " .. time
	lobbyLbl.Visible      = false
	endLbl.Visible        = false
end)

remotes.EndRound.OnClientEvent:Connect(function(winner)
	endLbl.Visible        = true
	endLbl.Text           = (winner and winner ~= "" and winner .. " wins!") or "Tie!"
	lobbyLbl.Visible      = false
	roundLbl.Visible      = false
end)
