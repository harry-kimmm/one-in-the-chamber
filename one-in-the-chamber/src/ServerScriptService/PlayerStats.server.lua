print("[PlayerStats] loaded")

local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	print("[PlayerStats] PlayerAdded:", player.Name)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name   = "leaderstats"
	leaderstats.Parent = player

	local kills = Instance.new("IntValue")
	kills.Name   = "Kills"
	kills.Value  = 0
	kills.Parent = leaderstats

	local coins = Instance.new("IntValue")
	coins.Name   = "Coins"
	coins.Value  = 0
	coins.Parent = player

	local ammo = Instance.new("IntValue")
	ammo.Name   = "Ammo"
	ammo.Value  = 0
	ammo.Parent = player
	print("[PlayerStats] Created Ammo IntValue for", player.Name)

	local inv = Instance.new("Folder", player)
	inv.Name = "Inventory"
	for _, item in ipairs({"Gun","Sword"}) do
		local v = Instance.new("BoolValue", inv)
		v.Name  = item
		v.Value = true
	end

	local er = Instance.new("StringValue", player)
	er.Name  = "EquippedRanged"
	er.Value = "Gun"

	local em = Instance.new("StringValue", player)
	em.Name  = "EquippedMelee"
	em.Value = "Sword"
end)
