-- ServerScriptService/PlayerDataStore.lua

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")

-- 1) your DataStore
local playerStore = DataStoreService:GetDataStore("PlayerData")

-- 2) default values if no data exists
local DEFAULT_DATA = {
	coins           = 0,
	inventory       = { Gun = true, Sword = true },
	equippedRanged  = "Gun",
	equippedMelee   = "Sword",
}

-- helper: safely load
local function loadPlayerData(userId)
	local success, data = pcall(function()
		return playerStore:GetAsync(tostring(userId))
	end)
	if success and type(data)=="table" then
		-- fill missing fields from defaults
		data.coins          = data.coins         or DEFAULT_DATA.coins
		data.inventory      = data.inventory     or DEFAULT_DATA.inventory
		data.equippedRanged = data.equippedRanged or DEFAULT_DATA.equippedRanged
		data.equippedMelee  = data.equippedMelee  or DEFAULT_DATA.equippedMelee
		return data
	else
		warn(string.format("[PlayerDataStore] couldn't load %d, using defaults", userId))
		-- return a copy of defaults
		return {
			coins           = DEFAULT_DATA.coins,
			inventory       = DEFAULT_DATA.inventory,
			equippedRanged  = DEFAULT_DATA.equippedRanged,
			equippedMelee   = DEFAULT_DATA.equippedMelee,
		}
	end
end

-- helper: safely save
local function savePlayerData(userId, data)
	local success, err = pcall(function()
		playerStore:SetAsync(tostring(userId), data)
	end)
	if not success then
		warn(string.format("[PlayerDataStore] failed to save %d: %s", userId, err))
	end
end

-- when a player joins, load & apply
local function onPlayerAdded(player)
	local data = loadPlayerData(player.UserId)

	-- ── leaderstats ──
	local stats = Instance.new("Folder", player)
	stats.Name = "leaderstats"

	local kills = Instance.new("IntValue", stats)
	kills.Name  = "Kills"
	kills.Value = 0

	-- ── coins ──
	local coins = Instance.new("IntValue", player)
	coins.Name  = "Coins"
	coins.Value = data.coins

	-- ── ammo ──
	local ammo = Instance.new("IntValue", player)
	ammo.Name  = "Ammo"
	ammo.Value = 0

	-- ── inventory folder ──
	local invFolder = Instance.new("Folder", player)
	invFolder.Name = "Inventory"
	for itemName, owned in pairs(data.inventory) do
		if owned then
			local v = Instance.new("BoolValue", invFolder)
			v.Name  = itemName
			v.Value = true
		end
	end

	-- ── equipped values ──
	local er = Instance.new("StringValue", player)
	er.Name  = "EquippedRanged"
	er.Value = data.equippedRanged

	local em = Instance.new("StringValue", player)
	em.Name  = "EquippedMelee"
	em.Value = data.equippedMelee
end

-- when they leave, gather current stats & save
local function onPlayerRemoving(player)
	-- build a plain Lua table
	local out = {}
	out.coins          = (player:FindFirstChild("Coins")         and player.Coins.Value)         or DEFAULT_DATA.coins
	out.inventory      = {}
	out.equippedRanged = (player:FindFirstChild("EquippedRanged") and player.EquippedRanged.Value) or DEFAULT_DATA.equippedRanged
	out.equippedMelee  = (player:FindFirstChild("EquippedMelee")  and player.EquippedMelee.Value)  or DEFAULT_DATA.equippedMelee

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
