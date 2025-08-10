local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("GameRemotes")
local KSUpd = Remotes:WaitForChild("KillStreakUpdate")

local LABEL_NAME = "StreakLabel"

local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

local label
local currentStreak = 0

local function findLabel()
	for _, d in ipairs(pg:GetDescendants()) do
		if d:IsA("TextLabel") and d.Name == LABEL_NAME then
			label = d
			local gui = label:FindFirstAncestorWhichIsA("ScreenGui")
			if gui then gui.ResetOnSpawn = false end
			return true
		end
	end
	return false
end

local function refresh()
	if not label or not label.Parent then return end
	if currentStreak >= 1 then
		label.Text = "Kill Streak: " .. tostring(currentStreak)
		label.Visible = true
	else
		label.Visible = false
	end
end

pg.DescendantAdded:Connect(function(obj)
	if obj:IsA("TextLabel") and obj.Name == LABEL_NAME then
		findLabel()
		refresh()
	elseif obj:IsA("ScreenGui") then
		-- if your GUI gets re-cloned, ensure it won't reset next time
		obj.ResetOnSpawn = false
	end
end)

KSUpd.OnClientEvent:Connect(function(streak)
	currentStreak = tonumber(streak) or 0
	if not label or not label.Parent then findLabel() end
	refresh()
end)

lp.CharacterAdded:Connect(function()
	currentStreak = 0
	if not label or not label.Parent then findLabel() end
	refresh()
end)

findLabel()
refresh()
