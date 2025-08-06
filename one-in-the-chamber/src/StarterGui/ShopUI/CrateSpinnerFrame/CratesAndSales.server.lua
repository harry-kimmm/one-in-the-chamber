local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes     = ReplicatedStorage:WaitForChild("GameRemotes")
local openCrate   = remotes:WaitForChild("OpenCrate")
local crateRes    = remotes:WaitForChild("CrateResult")
local purchase    = remotes:WaitForChild("PurchaseItem")
local purchaseRes = purchase
local equipItem   = remotes:WaitForChild("EquipItem")
local equipRes    = remotes:WaitForChild("EquipResult")

local shopRoot    = ReplicatedStorage:WaitForChild("Shop")
local cratesRoot  = shopRoot:WaitForChild("Crates")
local templates   = ReplicatedStorage:WaitForChild("ToolTemplates")

-- Auto-grant default items on join
Players.PlayerAdded:Connect(function(player)
	local inv = player:FindFirstChild("Inventory")
	if not inv then
		inv = Instance.new("Folder", player)
		inv.Name = "Inventory"
	end
	for _,name in ipairs({"Pistol","Sword"}) do
		if not inv:FindFirstChild(name) then
			local b = Instance.new("BoolValue", inv)
			b.Name, b.Value = name, true
		end
	end
	if not player:FindFirstChild("EquippedRanged") then
		local eq = Instance.new("StringValue", player)
		eq.Name, eq.Value = "EquippedRanged", "Pistol"
	end
	if not player:FindFirstChild("EquippedMelee") then
		local eq = Instance.new("StringValue", player)
		eq.Name, eq.Value = "EquippedMelee",  "Sword"
	end
end)

-- Weighted pick helper
local function weightedPick(drops)
	local sum = 0
	for _,d in ipairs(drops) do sum += d.Weight end
	local r = math.random(1, sum)
	for _,d in ipairs(drops) do
		r -= d.Weight
		if r <= 0 then return d end
	end
end

-- Crate opening
openCrate.OnServerEvent:Connect(function(player, crateName)
	local crate = cratesRoot:FindFirstChild(crateName); if not crate then return end
	local cost = crate:FindFirstChild("Cost")
	local coins = player:FindFirstChild("Coins")
	if not cost or not coins or coins.Value < cost.Value then
		crateRes:FireClient(player, false, crateName, nil, {})
		return
	end
	coins.Value -= cost.Value

	local raw = (crate:FindFirstChild("Drops") and crate.Drops:GetChildren()) or {}
	local drops = {}
	for _,v in ipairs(raw) do
		if v:IsA("IntValue") then
			table.insert(drops, {Name=v.Name, Weight=v.Value})
		end
	end

	local pick = weightedPick(drops)
	local won  = pick and pick.Name

	if won then
		local inv = player:FindFirstChild("Inventory")
		local b = Instance.new("BoolValue", inv)
		b.Name, b.Value = won, true
		local flag = Instance.new("BoolValue", b)
		flag.Name, flag.Value = "FromCrate", true
	end

	local out, cat = {}, crateName:match("^(%a+)Crate$")
	for _,d in ipairs(drops) do
		local tmpl = templates[cat] and templates[cat]:FindFirstChild(d.Name)
		local icon = tmpl and tmpl:FindFirstChild("IconID") and tmpl.IconID.Value or ""
		local rar  = tmpl and tmpl:FindFirstChild("Rarity") and tmpl.Rarity.Value or "Common"
		table.insert(out, {
			Name     = d.Name,
			Weight   = d.Weight,
			Category = cat,
			IconID   = icon,
			Rarity   = rar,
		})
	end

	crateRes:FireClient(player, true, crateName, won, out)
end)

-- Purchase handler (now checks ownership)
purchase.OnServerEvent:Connect(function(player, category, itemName)
	if type(category)~="string" or type(itemName)~="string" then
		purchaseRes:FireClient(player, false, "Invalid")
		return
	end
	local inv = player:FindFirstChild("Inventory")
	if inv:FindFirstChild(itemName) then
		purchaseRes:FireClient(player, false, "Already owned")
		return
	end
	local folder = shopRoot:FindFirstChild(category)
	local proto  = folder and folder:FindFirstChild(itemName)
	local cost   = proto and proto:FindFirstChild("Cost")
	local coins  = player:FindFirstChild("Coins")
	if not proto or not cost or not coins or coins.Value < cost.Value then
		purchaseRes:FireClient(player, false, "Can't buy")
		return
	end
	coins.Value -= cost.Value
	local b = Instance.new("BoolValue", inv)
	b.Name, b.Value = itemName, true
	purchaseRes:FireClient(player, true, itemName)
end)

-- Equip handler
equipItem.OnServerEvent:Connect(function(player, category, itemName)
	if type(category)~="string" or type(itemName)~="string" then
		equipRes:FireClient(player, false, "Invalid")
		return
	end
	local inv = player:FindFirstChild("Inventory")
	if not inv or not inv:FindFirstChild(itemName) then
		equipRes:FireClient(player, false, "Not owned")
		return
	end
	if category == "Ranged" then
		player.EquippedRanged.Value = itemName
	else
		player.EquippedMelee.Value  = itemName
	end
	equipRes:FireClient(player, true, category, itemName)
end)
