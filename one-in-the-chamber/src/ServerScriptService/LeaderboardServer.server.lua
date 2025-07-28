local DataStoreService = game:GetService("DataStoreService")
local RS               = game:GetService("ReplicatedStorage")
local remotes          = RS:WaitForChild("GameRemotes")

-- ensure RemoteFunction exists
local getBoard = remotes:FindFirstChild("GetLeaderboard")
if not getBoard then
	getBoard = Instance.new("RemoteFunction")
	getBoard.Name   = "GetLeaderboard"
	getBoard.Parent = remotes
end

local stores = {
	Wins = {
		Lifetime = DataStoreService:GetOrderedDataStore("Leaderboard_Wins_Lifetime"),
		Weekly   = DataStoreService:GetOrderedDataStore("Leaderboard_Wins_Weekly"),
		Daily    = DataStoreService:GetOrderedDataStore("Leaderboard_Wins_Daily"),
	},
	Kills = {
		Lifetime = DataStoreService:GetOrderedDataStore("Leaderboard_Kills_Lifetime"),
		Weekly   = DataStoreService:GetOrderedDataStore("Leaderboard_Kills_Weekly"),
		Daily    = DataStoreService:GetOrderedDataStore("Leaderboard_Kills_Daily"),
	},
}

getBoard.OnServerInvoke = function(player, statType, period, limit)
	limit = limit or 10
	local ds = stores[statType] and stores[statType][period]
	if not ds then return {} end
	local page = ds:GetSortedAsync(false, limit)
	local data = page:GetCurrentPage()
	local result = {}
	for _, entry in ipairs(data) do
		table.insert(result, {
			userId = tonumber(entry.key),
			value  = entry.value,
		})
	end
	return result
end
