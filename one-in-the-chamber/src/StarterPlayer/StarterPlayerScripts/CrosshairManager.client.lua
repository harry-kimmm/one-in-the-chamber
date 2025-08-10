local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player  = Players.LocalPlayer
local mouse   = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("GameRemotes")

local evBeginRound = remotes:WaitForChild("BeginRound")
local evEndRound   = remotes:WaitForChild("EndRound")

local defaultIcon  = mouse.Icon
local roundIcon    = "rbxassetid://9524023207"

local stateFolder  = ReplicatedStorage:WaitForChild("RoundState")
local phaseVal     = stateFolder:WaitForChild("Phase")

local inRound = false

local function updateCrosshair()
	mouse.Icon = inRound and roundIcon or defaultIcon
end

evBeginRound.OnClientEvent:Connect(function()
	inRound = true
	updateCrosshair()
end)

evEndRound.OnClientEvent:Connect(function()
	inRound = false
	updateCrosshair()
end)

player.CharacterAdded:Connect(function()
	mouse = player:GetMouse()
	updateCrosshair()
end)

local function syncFromPhase()
	inRound = (phaseVal.Value == "Round")
	updateCrosshair()
end

syncFromPhase()
phaseVal.Changed:Connect(syncFromPhase)
