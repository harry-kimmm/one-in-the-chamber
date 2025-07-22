ssssssssssssslocal RS       = game:GetService("ReplicatedStorage")
local shop     = RS:WaitForChild("Shop")
local remotes  = RS:WaitForChild("GameRemotes")
local purchase = remotes:WaitForChild("PurchaseItem")
local equip    = remotes:WaitForChild("EquipItem")

purchase.OnServerEvent:Connect(function(player, category, itemName)
	local folder = shop:FindFirstChild(category)
	if not folder then return end
	local item    = folder:FindFirstChild(itemName)
	local costVal = item and item:FindFirstChild("Cost")
	if not item or not costVal then return end

	local coins = player:FindFirstChild("Coins")
	print(string.format(
		"[ShopServer] %s has %s coins; cost of %s is %s",
		player.Name,
		coins and coins.Value or "nil",
		itemName,
		costVal.Value
		))

	if not coins or coins.Value < costVal.Value then
		purchase:FireClient(player, false, "Not enough coins")
		return
	end

	coins.Value = coins.Value - costVal.Value
	local inv = player:FindFirstChild("Inventory")
	if inv and not inv:FindFirstChild(itemName) then
		local v = Instance.new("BoolValue", inv)
		v.Name  = itemName
		v.Value = true
	end

	purchase:FireClient(player, true, itemName)
end)

equip.OnServerEvent:Connect(function(player, category, itemName)
	local inv = player:FindFirstChild("Inventory")
	if not inv or not inv:FindFirstChild(itemName) then
		equip:FireClient(player, false, "Not owned")
		return
	end

	if category == "Ranged" then
		player.EquippedRanged.Value = itemName
	else
		player.EquippedMelee.Value = itemName
	end

	equip:FireClient(player, true, category, itemName)
end)
