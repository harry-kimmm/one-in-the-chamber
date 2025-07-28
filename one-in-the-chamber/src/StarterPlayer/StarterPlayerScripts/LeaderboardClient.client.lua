local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local remotes = RS:WaitForChild("GameRemotes")
local localPlayer = Players.LocalPlayer

local function buildEntry(parent, userId, score)
	local frame = Instance.new("Frame", parent)
	frame.Size = UDim2.new(1, 0, 0, 50)
	frame.BackgroundTransparency = 1

	local avatar = Instance.new("ImageLabel", frame)
	avatar.Size = UDim2.new(0, 50, 0, 50)
	avatar.Position = UDim2.new(0, 0, 0, 0)
	avatar.BackgroundTransparency = 1
	avatar.Image = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size50x50)

	local nameLabel = Instance.new("TextLabel", frame)
	nameLabel.Size = UDim2.new(0, 150, 0, 25)
	nameLabel.Position = UDim2.new(0, 55, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = Players:GetNameFromUserIdAsync(userId)

	local scoreLabel = Instance.new("TextLabel", frame)
	scoreLabel.Size = UDim2.new(0, 100, 0, 25)
	scoreLabel.Position = UDim2.new(0, 55, 0, 25)
	scoreLabel.BackgroundTransparency = 1
	scoreLabel.Text = tostring(score)
end

local function setupBoard(part)
	local gui = part:WaitForChild("BoardGui")
	local toggles = gui:WaitForChild("ToggleFrame")
	local list = gui:WaitForChild("EntryList")
	local statType = (part.Name == "WinsBoard") and "Wins" or "Kills"

	local function refresh(period)
		for _, child in ipairs(list:GetChildren()) do child:Destroy() end
		local data = remotes:GetLeaderboard(statType, period, 10)
		for _, entry in ipairs(data) do
			buildEntry(list, entry.userId, entry.value)
		end
	end

	toggles.LifetimeButton.MouseButton1Click:Connect(function() refresh("Lifetime") end)
	toggles.WeeklyButton.MouseButton1Click:Connect(function()   refresh("Weekly")   end)
	toggles.DailyButton.MouseButton1Click:Connect(function()    refresh("Daily")    end)

	refresh("Lifetime")
end

for _, part in ipairs(workspace:WaitForChild("Leaderboards"):GetChildren()) do
	if part:IsA("BasePart") then
		setupBoard(part)
	end
end
