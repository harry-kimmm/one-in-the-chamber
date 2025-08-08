local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local FirstPlaceEvent = RS:WaitForChild("GameRemotes"):WaitForChild("FirstPlaceUpdate")

local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

local hud, label, sfx
local isLeaderNow = false

local function wireLabel()
	hud = pg:FindFirstChild("HUD")
	if not hud then return end
	hud.ResetOnSpawn = false
	label = hud:FindFirstChild("FirstPlaceLabel")
	if not label then return end
	sfx = label:FindFirstChild("Sound")
	if isLeaderNow then
		label.Text = "First Place, Aura Activated!"
		label.Visible = true
	else
		label.Visible = false
	end
end

wireLabel()

pg.ChildAdded:Connect(function(child)
	if child.Name == "HUD" then
		wireLabel()
	end
end)

FirstPlaceEvent.OnClientEvent:Connect(function(isLeader)
	isLeaderNow = isLeader and true or false
	if not label or not label.Parent then wireLabel() end
	if not label then return end
	if isLeaderNow then
		label.Text = "First Place, Aura Activated!"
		label.Visible = true
		if sfx and sfx.SoundId ~= "" then
			if sfx.IsPlaying then sfx:Stop() end
			sfx:Play()
		end
	else
		label.Visible = false
	end
end)

lp.CharacterAdded:Connect(function()
	task.defer(function()
		if not label or not label.Parent then wireLabel() end
		if label then
			if isLeaderNow then
				label.Text = "First Place, Aura Activated!"
				label.Visible = true
			else
				label.Visible = false
			end
		end
	end)
end)
