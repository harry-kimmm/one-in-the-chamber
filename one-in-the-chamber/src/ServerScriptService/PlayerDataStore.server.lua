local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local playerStore      = DataStoreService:GetDataStore("PlayerData")

local DEFAULT_DATA = {
	coins         = 0,
	inventory     = { Gun = true, Sword = true },
	equippedRanged  = "Gun",
	equippedMelee   = "Sword",
	wins          = 0,
	lifetimeKills = 0,
}

local function loadPlayerData(userId)
	local ok, data = pcall(function()
		return playerStore:GetAsync(tostring(userId))
	end)
	if ok and type(data) == "table" then
		data.coins         = data.coins         or DEFAULT_DATA.coins
		data.inventory     = data.inventory     or DEFAULT_DATA.inventory
		data.equippedRanged  = data.equippedRanged  or DEFAULT_DATA.equippedRanged
		data.equippedMelee   = data.equippedMelee   or DEFAULT_DATA.equippedMelee
		data.wins          = data.wins          or DEFAULT_DATA.wins
		data.lifetimeKills = data.lifetimeKills or DEFAULT_DATA.lifetimeKills
		return data
	else
		return {
			coins         = DEFAULT_DATA.coins,
			inventory     = DEFAULT_DATA.inventory,
			equippedRanged  = DEFAULT_DATA.equippedRanged,
			equippedMelee   = DEFAULT_DATA.equippedMelee,
			wins          = DEFAULT_DATA.wins,
			lifetimeKills = DEFAULT_DATA.lifetimeKills,
		}
	end
end

local function savePlayerData(userId, data)
	pcall(function()
		playerStore:SetAsync(tostring(userId), data)
	end)
end

local function onPlayerAdded(player)
	local data = loadPlayerData(player.UserId)

	local statsFolder = Instance.new("Folder")
	statsFolder.Name   = "leaderstats"
	statsFolder.Parent = player

	local kills = Instance.new("IntValue")
	kills.Name   = "Kills"
	kills.Value  = 0
	kills.Parent = statsFolder

	local wins = Instance.new("IntValue")
	wins.Name   = "Wins"
	wins.Value  = data.wins
	wins.Parent = player

	local lifetimeKills = Instance.new("IntValue")
	lifetimeKills.Name   = "LifetimeKills"
	lifetimeKills.Value  = data.lifetimeKills
	lifetimeKills.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name   = "Coins"
	coins.Value  = data.coins
	coins.Parent = player

	local ammo = Instance.new("IntValue")
	ammo.Name   = "Ammo"
	ammo.Value  = 0
	ammo.Parent = player

	local invFolder = Instance.new("Folder")
	invFolder.Name   = "Inventory"
	invFolder.Parent = player
	for itemName, owned in pairs(data.inventory) do
		if owned then
			local v = Instance.new("BoolValue")
			v.Name   = itemName
			v.Value  = true
			v.Parent = invFolder
		end
	end

	local er = Instance.new("StringValue")
	er.Name   = "EquippedRanged"
	er.Value  = data.equippedRanged
	er.Parent = player

	local em = Instance.new("StringValue")
	em.Name   = "EquippedMelee"
	em.Value  = data.equippedMelee
	em.Parent = player
end

local function onPlayerRemoving(player)
	local out = {}
	out.coins         = (player:FindFirstChild("Coins")         and player.Coins.Value)         or DEFAULT_DATA.coins
	out.inventory     = {}
	out.equippedRanged  = (player:FindFirstChild("EquippedRanged") and player.EquippedRanged.Value) or DEFAULT_DATA.equippedRanged
	out.equippedMelee   = (player:FindFirstChild("EquippedMelee")  and player.EquippedMelee.Value)  or DEFAULT_DATA.equippedMelee
	out.wins          = (player:FindFirstChild("Wins")           and player.Wins.Value)           or DEFAULT_DATA.wins
	out.lifetimeKills = (player:FindFirstChild("LifetimeKills")  and player.LifetimeKills.Value)  or DEFAULT_DATA.lifetimeKills

	local invFolder = player:FindFirstChild("Inventory")
	if invFolder then
		for _, v in ipairs(invFolder:GetChildren()) do
			if v:IsA("BoolValue") then
				out.inventory[v.Name] = v.Value
			end
		end
	end

	savePlayerData(player.UserId, out)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
