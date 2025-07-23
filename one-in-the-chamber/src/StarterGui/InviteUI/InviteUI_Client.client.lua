-- StarterGui/InviteUI/InviteUI_Client.lua

local Players       = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local RS            = game:GetService("ReplicatedStorage")

local player        = Players.LocalPlayer
local remotes       = RS:WaitForChild("GameRemotes")
local startLobbyEvt = remotes:WaitForChild("StartLobby")
local beginRoundEvt = remotes:WaitForChild("BeginRound")

local ui        = script.Parent
local openBtn   = ui:WaitForChild("OpenInviteButton")

local lobbyInitialized = false
local roundClosed      = false

openBtn.MouseButton1Click:Connect(function()
	SocialService:PromptGameInvite(player)
end)

startLobbyEvt.OnClientEvent:Connect(function()
	if lobbyInitialized then return end
	lobbyInitialized = true
	roundClosed      = false

	ui.Enabled      = true
	openBtn.Visible = true
end)

beginRoundEvt.OnClientEvent:Connect(function()
	if roundClosed then return end
	openBtn.Visible = false
	ui.Enabled      = false

	roundClosed      = true
	lobbyInitialized = false
end)
