-- StarterGui/HUD/HUD_Client.lua

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local player   = Players.LocalPlayer
local coinLbl  = script.Parent:WaitForChild("CoinDisplay")
local ammoLbl  = script.Parent:WaitForChild("AmmoDisplay")

local coinsVal = player:WaitForChild("Coins")
local ammoVal  = player:WaitForChild("Ammo")

local remotes  = RS:WaitForChild("GameRemotes")
local evLobby  = remotes:WaitForChild("StartLobby")
local evRound  = remotes:WaitForChild("StartRound")
local evEnd    = remotes:WaitForChild("EndRound")

local inRound = false

-- Helper to redraw ammo text
local function updateAmmo()
	ammoLbl.Text = "Ammo: "..ammoVal.Value
end

-- INITIALIZE labels
coinLbl.Text = ""..coinsVal.Value
ammoLbl.Text = "Ammo: "..ammoVal.Value
ammoLbl.Visible = false

-- RESPOND to stat changes
coinsVal.Changed:Connect(function(v)
	coinLbl.Text = ""..v
end)
ammoVal.Changed:Connect(updateAmmo)

-- SHOW/HIDE on phase events
evLobby.OnClientEvent:Connect(function(_)
	inRound = false
	ammoLbl.Visible = false
end)
evRound.OnClientEvent:Connect(function(_)
	inRound = true
	ammoLbl.Visible = true
	updateAmmo()
end)
evEnd.OnClientEvent:Connect(function(_)
	inRound = false
	ammoLbl.Visible = false
end)

-- CATCH YOUR RESPAWN and immediately redraw
player.CharacterAdded:Connect(function()
	-- small delay so server has time to reset Ammo
	wait(0.1)
	if inRound then
		updateAmmo()
		ammoLbl.Visible = true
	else
		ammoLbl.Visible = false
	end
end)
