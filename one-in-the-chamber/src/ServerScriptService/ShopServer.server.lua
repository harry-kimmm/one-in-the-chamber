local RS = game:GetService("ReplicatedStorage")
local shop = RS:WaitForChild("Shop")
local remotes = RS:WaitForChild("GameRemotes")
local purchase = remotes:WaitForChild("PurchaseItem")
local equip     = remotes:WaitForChild("EquipItem")

purchase.OnServerEvent:Connect(function(player, category, itemName)
	local folder  = shop:FindFirstChild(category)
	local item    = folder and folder:FindFirstChild(itemName)
	local costVal = item and item:FindFirstChild("Cost")
	if not item or not costVal then return end

	local inv = player:FindFirstChild("Inventory")
	if inv and inv:FindFirstChild(itemName) then
		purchase:FireClient(player, false, "Already owned")
		return
	end

	local coins = player:FindFirstChild("Coins")
	if not coins or coins.Value < costVal.Value then
		purchase:FireClient(player, false, "Not enough coins")
		return
	end

	coins.Value = coins.Value - costVal.Value
	if inv then
		local v = Instance.new("BoolValue", inv)
		v.Name  = itemName
		v.Value = true
	end

	purchase:FireClient(player, true, itemName)
end)

equip.OnServerEvent:Connect(function(player, category, itemName)
	local inv = player:FindFirstChild("Inventory")
	if not inv or not inv:FindFirstChild(itemName) then
		equip:FireClient(player, false, category, itemName)
		return
	end

	if category == "Ranged" then
		player.EquippedRanged.Value = itemName
	else
		player.EquippedMelee.Value = itemName
	end

	equip:FireClient(player, true, category, itemName)
end)
