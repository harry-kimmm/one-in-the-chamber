local DataStoreService = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")
local remotes = RS:WaitForChild("GameRemotes")

local getBoard = remotes:FindFirstChild("GetLeaderboard")
if not getBoard then
	getBoard = Instance.new("RemoteFunction")
	getBoard.Name = "GetLeaderboard"
	getBoard.Parent = remotes
end

local function dayKey()
	local t = os.date("!*t")
	return string.format("%04d%02d%02d", t.year, t.month, t.day)
end

local function weekKey()
	local t = os.date("!*t")
	local w = math.floor((t.yday - 1) / 7) + 1
	return string.format("%04dW%02d", t.year, w)
end

local function storeName(statType, period)
	if period == "Lifetime" then
		return "LB_" .. statType .. "_Lifetime"
	elseif period == "Weekly" then
		return "LB_" .. statType .. "_Weekly_" .. weekKey()
	else
		return "LB_" .. statType .. "_Daily_" .. dayKey()
	end
end

getBoard.OnServerInvoke = function(_, statType, period, limit)
	limit = limit or 10
	local name = storeName(statType, period)
	local ods = DataStoreService:GetOrderedDataStore(name)
	local page = ods:GetSortedAsync(false, limit)
	local data = page:GetCurrentPage()
	local out = {}
	for _, row in ipairs(data) do
		table.insert(out, { userId = tonumber(row.key), value = row.value })
	end
	return out
end
