local RS = game:GetService("ReplicatedStorage")
local remotes = RS:WaitForChild("GameRemotes")
local toggleEvt = remotes:WaitForChild("ProfileToggle")
local openBtn = script.Parent:WaitForChild("OpenProfileButton")
local frame = script.Parent:WaitForChild("ProfileFrame")

toggleEvt.OnClientEvent:Connect(function(show)
	openBtn.Visible = show
	if not show then
		frame.Visible = false
	end
end)
