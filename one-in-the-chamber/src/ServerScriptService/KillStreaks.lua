-- KillStreaks (ModuleScript)
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local remotes = RS:WaitForChild("GameRemotes")
local KSUpd  = remotes:WaitForChild("KillStreakUpdate")

local killStreaks = {}

local function fire(player, newCount)
	KSUpd:FireClient(player, newCount)
end

local M = {}

function M.AddKill(player)
	local prev = killStreaks[player] or 0
	local now  = prev + 1
	killStreaks[player] = now
	fire(player, now)
	return now
end

function M.Reset(player)
	killStreaks[player] = 0
	fire(player, 0)
end

Players.PlayerAdded:Connect(function(pl)
	pl.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")
		hum.Died:Connect(function()
			M.Reset(pl)
		end)
	end)
	M.Reset(pl)
end)
Players.PlayerRemoving:Connect(function(pl)
	killStreaks[pl] = nil
end)

return M
