local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes           = ReplicatedStorage:WaitForChild("GameRemotes")

local openCrate = remotes:WaitForChild("OpenCrate")
local crateRes  = remotes:WaitForChild("CrateResult")
local sellItem  = remotes:WaitForChild("SellItem")
local sellRes   = remotes:WaitForChild("SellResult")

local shop       = ReplicatedStorage:WaitForChild("Shop")
local cratesRoot = shop:WaitForChild("Crates")
local templates  = ReplicatedStorage:WaitForChild("ToolTemplates")

local function weightedPick(drops)
	local total = 0
	for _,d in ipairs(drops) do total += d.Weight end
	local r = math.random(1, total)
	for _,d in ipairs(drops) do
		r -= d.Weight
		if r <= 0 then return d end
	end
end

openCrate.OnServerEvent:Connect(function(player, crateName)
	local crate   = cratesRoot:FindFirstChild(crateName)
	if not crate then return end
	local costVal = crate:FindFirstChild("Cost")
	local coins   = player:FindFirstChild("Coins")
	if not costVal or not coins or coins.Value < costVal.Value then
		crateRes:FireClient(player,false,crateName,nil,{})
		return
	end
	coins.Value -= costVal.Value

	-- gather drop weights
	local dropsFolder = crate:FindFirstChild("Drops")
	if not dropsFolder then return end
	local raw = dropsFolder:GetChildren()
	local drops = {}
	for _,v in ipairs(raw) do
		if v:IsA("IntValue") then
			table.insert(drops,{Name=v.Name,Weight=v.Value})
		end
	end

	local pick = weightedPick(drops)
	local won  = pick.Name

	-- always add a new BoolValue instance (duplicates allowed)
	local inv = player:FindFirstChild("Inventory")
	if inv then
		local b = Instance.new("BoolValue",inv)
		b.Name  = won
		b.Value = true
		local flag = Instance.new("BoolValue",b)
		flag.Name  = "FromCrate"
		flag.Value = true
	end

	-- build full drop info for spinner
	local out = {}
	local cat = crateName:match("^(%a+)Crate$")
	for _,d in ipairs(drops) do
		local tmpl = templates[cat] and templates[cat]:FindFirstChild(d.Name)
		local icon,rar = "", "Common"
		if tmpl then
			local i = tmpl:FindFirstChild("IconID")
			if i then icon = i.Value end
			local r = tmpl:FindFirstChild("Rarity")
			if r then rar = r.Value end
		end
		table.insert(out,{
			Name     = d.Name,
			Weight   = d.Weight,
			Category = cat,
			IconID   = icon,
			Rarity   = rar,
		})
	end

	crateRes:FireClient(player,true,crateName,won,out)
end)

sellItem.OnServerEvent:Connect(function(player, itemInstance)
	-- itemInstance is the BoolValue under Inventory
	if typeof(itemInstance) ~= "Instance" or not itemInstance:IsA("BoolValue") then
		sellRes:FireClient(player,false,nil,0)
		return
	end
	if itemInstance.Parent ~= player.Inventory or not itemInstance:FindFirstChild("FromCrate") then
		sellRes:FireClient(player,false,itemInstance.Name,0)
		return
	end

	local itemName = itemInstance.Name
	local tmpl = templates.Ranged:FindFirstChild(itemName)
		or templates.Melee:FindFirstChild(itemName)
	local rar = tmpl and tmpl:FindFirstChild("Rarity") and tmpl.Rarity.Value or "Common"
	local prices = {Common=50,Uncommon=125,Rare=450,Epic=750,Legendary=1000}
	local price = prices[rar] or 0

	local coins = player:FindFirstChild("Coins")
	if coins then coins.Value += price end

	itemInstance:Destroy()
	sellRes:FireClient(player,true,itemName,price)
end)
