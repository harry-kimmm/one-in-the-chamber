local Players = game:GetService("Players")
local player  = Players.LocalPlayer
local ui      = script.Parent

local openBtn     = ui:WaitForChild("OpenProfileButton")
local frame       = ui:WaitForChild("ProfileFrame")
local avatarImage = frame:WaitForChild("AvatarImage")
local killsLabel  = frame:WaitForChild("KillsLabel")
local winsLabel   = frame:WaitForChild("WinsLabel")
local closeBtn    = frame:WaitForChild("CloseButton")

openBtn.MouseButton1Click:Connect(function()
	frame.Visible = true
	avatarImage.Image = Players:GetUserThumbnailAsync(
		player.UserId,
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size100x100
	)
	killsLabel.Text = "Total Kills: " .. player:WaitForChild("LifetimeKills").Value
	winsLabel.Text  = "Total Wins: "  .. player:WaitForChild("Wins").Value
end)

closeBtn.MouseButton1Click:Connect(function()
	frame.Visible = false
end)
