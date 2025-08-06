-- ShopServer.lua  (ServerScriptService)

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")

-- References
local shop      = RS:WaitForChild("Shop")
local remotes   = RS:WaitForChild("GameRemotes")
local purchase  = remotes:WaitForChild("PurchaseItem")
local equip     = remotes:WaitForChild("EquipItem")

-- 1) Default starter inventory
Players.PlayerAdded:Connect(function(player)
	local inv = player:FindFirstChild("Inventory")
	if not inv then
		inv = Instance.new("Folder", player)
		inv.Name = "Inventory"
	end
	-- Only add defaults if Inventory is empty
	if #inv:GetChildren() == 0 then
		for _, name in ipairs({"StarterGun", "StarterSword"}) do
			local b = Instance.new("BoolValue", inv)
			b.Name  = name
			b.Value = true
		end
	end
end)

-- 2) Purchase handler
purchase.OnServerEvent:Connect(function(player, category, itemName)
	-- Validate args
	if type(category) ~= "string" or type(itemName) ~= "string" then
		purchase:FireClient(player, false, "Invalid purchase request")
		return
	end

	-- Locate the shop folder and item
	local folder  = shop:FindFirstChild(category)
	local item    = folder and folder:FindFirstChild(itemName)
	local costVal = item and item:FindFirstChild("Cost")
	if not folder or not item or not costVal then
		purchase:FireClient(player, false, "Item not found")
		return
	end

	-- Check currency
	local coins = player:FindFirstChild("Coins")
	if not coins or coins.Value < costVal.Value then
		purchase:FireClient(player, false, "Not enough coins")
		return
	end

	-- Deduct & grant
	coins.Value -= costVal.Value
	local inv = player:FindFirstChild("Inventory")
	if inv and not inv:FindFirstChild(itemName) then
		local v = Instance.new("BoolValue", inv)
		v.Name  = itemName
		v.Value = true
	end

	purchase:FireClient(player, true, itemName)
end)

-- 3) Equip handler
equip.OnServerEvent:Connect(function(player, category, itemName)
	-- Validate args
	if type(category) ~= "string" or type(itemName) ~= "string" then
		equip:FireClient(player, false, "Invalid equip request")
		return
	end

	-- Confirm ownership
	local inv = player:FindFirstChild("Inventory")
	if not inv or not inv:FindFirstChild(itemName) then
		equip:FireClient(player, false, "You don't own that")
		return
	end

	-- Set the correct equipped value
	if category == "Ranged" then
		player.EquippedRanged.Value = itemName
	else
		player.EquippedMelee.Value  = itemName
	end

	equip:FireClient(player, true, category, itemName)
end)
