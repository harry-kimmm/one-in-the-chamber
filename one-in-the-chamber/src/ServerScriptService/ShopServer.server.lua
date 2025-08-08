-- ServerScriptService → ShopServer.lua

local RS       = game:GetService("ReplicatedStorage")
local shop     = RS:WaitForChild("Shop")
local remotes  = RS:WaitForChild("GameRemotes")

local purchase = remotes:WaitForChild("PurchaseItem")
local equip    = remotes:WaitForChild("EquipItem")
local equipRes = remotes:WaitForChild("EquipResult")

local toolsRoot  = RS:WaitForChild("ToolTemplates") -- Ranged, Melee
local aurasRoot  = RS:WaitForChild("Auras")

local function getTemplateFolder(cat)
	if cat == "Ranged" or cat == "Melee" then
		return toolsRoot[cat]
	elseif cat == "Auras" then
		return aurasRoot
	end
end

purchase.OnServerEvent:Connect(function(player, category, itemName)
	local catFolder = shop:FindFirstChild(category)
	local tmplRoot  = getTemplateFolder(category)
	if not catFolder or not tmplRoot then return end

	local item    = catFolder:FindFirstChild(itemName)
	local tmpl    = tmplRoot:FindFirstChild(itemName)
	local costVal = item and item:FindFirstChild("Cost")

	-- Block purchase if aura is not shop-sellable
	if category == "Auras" and tmpl then
		local sell = tmpl:FindFirstChild("ShopSellable")
		if sell and sell.Value == false then
			remotes.PurchaseItem:FireClient(player,false,"Not purchasable")
			return
		end
	end

	if not item or not costVal then return end

	local coins = player:FindFirstChild("Coins")
	if not coins or coins.Value < costVal.Value then
		remotes.PurchaseItem:FireClient(player,false,"Not enough coins")
		return
	end

	-- Shop doesn't create duplicates; just mark owned if missing
	local inv = player:FindFirstChild("Inventory")
	if inv and not inv:FindFirstChild(itemName) then
		local v = Instance.new("BoolValue")
		v.Name, v.Value, v.Parent = itemName, true, inv
	end

	coins.Value -= costVal.Value
	remotes.PurchaseItem:FireClient(player,true,itemName)
end)

equip.OnServerEvent:Connect(function(player, category, itemName)
	local inv = player:FindFirstChild("Inventory")
	if not inv or not inv:FindFirstChild(itemName) then
		equipRes:FireClient(player,false,category,itemName)
		return
	end

	if category == "Ranged" then
		if player:FindFirstChild("EquippedRanged") then
			player.EquippedRanged.Value = itemName
		end
	elseif category == "Melee" then
		if player:FindFirstChild("EquippedMelee") then
			player.EquippedMelee.Value = itemName
		end
	elseif category == "Auras" then
		if player:FindFirstChild("EquippedAura") then
			player.EquippedAura.Value = itemName
		end
	end

	equipRes:FireClient(player,true,category,itemName)
end)
