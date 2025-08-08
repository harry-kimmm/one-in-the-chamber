-- ServerScriptService → CratesAndSales.lua

local RS        = game:GetService("ReplicatedStorage")
local remotes   = RS:WaitForChild("GameRemotes")

local openCrate = remotes:WaitForChild("OpenCrate")
local crateRes  = remotes:WaitForChild("CrateResult")

local shop       = RS:WaitForChild("Shop")
local cratesRoot = shop:WaitForChild("Crates")
local toolsRoot  = RS:WaitForChild("ToolTemplates")
local aurasRoot  = RS:WaitForChild("Auras")

local function weightedPick(drops)
	local total = 0
	for _,d in ipairs(drops) do total += d.Weight end
	local r = math.random(1,total)
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

	-- read drops
	local dropsFolder = crate:FindFirstChild("Drops")
	if not dropsFolder then return end
	local drops = {}
	for _,v in ipairs(dropsFolder:GetChildren()) do
		if v:IsA("IntValue") then
			table.insert(drops, {Name=v.Name, Weight=v.Value})
		end
	end
	if #drops == 0 then
		crateRes:FireClient(player,false,crateName,nil,{})
		return
	end

	-- pick winner
	local pick = weightedPick(drops)
	local won  = pick.Name

	-- crates allow duplicates
	local inv = player:FindFirstChild("Inventory")
	if inv then
		local b = Instance.new("BoolValue")
		b.Name, b.Value, b.Parent = won, true, inv
		local flag = Instance.new("BoolValue")
		flag.Name, flag.Value, flag.Parent = "FromCrate", true, b
	end

	-- spinner data: detect category/rarity per drop across repos
	local function findTemplateAndCategory(itemName)
		if toolsRoot.Ranged:FindFirstChild(itemName) then
			return toolsRoot.Ranged[itemName], "Ranged"
		elseif toolsRoot.Melee:FindFirstChild(itemName) then
			return toolsRoot.Melee[itemName], "Melee"
		elseif aurasRoot:FindFirstChild(itemName) then
			return aurasRoot[itemName], "Auras"
		end
		return nil, "Unknown"
	end

	local out = {}
	for _,d in ipairs(drops) do
		local tmpl, cat = findTemplateAndCategory(d.Name)
		local rar = "Common"
		local iconId = ""

		if tmpl and tmpl:FindFirstChild("Rarity") then
			rar = tmpl.Rarity.Value
		end
		if tmpl and cat ~= "Auras" and tmpl:FindFirstChild("IconID") and tostring(tmpl.IconID.Value) ~= "" then
			iconId = "rbxassetid://"..tostring(tmpl.IconID.Value)
		end

		table.insert(out, {
			Name     = d.Name,
			Weight   = d.Weight,
			Category = cat,
			IconID   = iconId,
			Rarity   = rar,
		})
	end

	crateRes:FireClient(player, true, crateName, won, out)
end)
