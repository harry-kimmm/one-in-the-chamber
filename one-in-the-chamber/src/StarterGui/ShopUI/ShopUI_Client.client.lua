local Players         = game:GetService("Players")
local RS              = game:GetService("ReplicatedStorage")
local player          = Players.LocalPlayer

local remotes         = RS:WaitForChild("GameRemotes")
local purchaseRemote  = remotes:WaitForChild("PurchaseItem")
local equipRemote     = remotes:WaitForChild("EquipItem")
local startLobbyEvt   = remotes:WaitForChild("StartLobby")
local beginRoundEvt   = remotes:WaitForChild("BeginRound")

local shopFolder      = RS:WaitForChild("Shop")
local templates       = RS:WaitForChild("ToolTemplates")

local ui              = script.Parent
local openBtn         = ui:WaitForChild("OpenShopButton")
local shopFrame       = ui:WaitForChild("ShopFrame")
local closeBtn        = shopFrame:WaitForChild("CloseButton")
local rangedTab       = shopFrame:WaitForChild("RangedTab")
local meleeTab        = shopFrame:WaitForChild("MeleeTab")
local rangedList      = shopFrame:WaitForChild("RangedList")
local meleeList       = shopFrame:WaitForChild("MeleeList")
local itemTemplate    = shopFrame:WaitForChild("ItemTemplate")
local details         = shopFrame:WaitForChild("DetailsFrame")

local inv             = player:WaitForChild("Inventory")
local eqr             = player:WaitForChild("EquippedRanged")
local eqm             = player:WaitForChild("EquippedMelee")
local coins           = player:WaitForChild("Coins")

local rarityColor     = {
	Basic     = Color3.fromRGB(200,200,200),
	Common    = Color3.fromRGB(170,170,170),
	Uncommon  = Color3.fromRGB(100,255,100),
	Rare      = Color3.fromRGB(100,150,255),
	Epic      = Color3.fromRGB(200,100,255),
	Legendary = Color3.fromRGB(255,200,100),
}

local lobbyInitialized = false

local function clearList(frame)
	for _, c in ipairs(frame:GetChildren()) do
		if c:IsA("TextButton") and c ~= itemTemplate then
			c:Destroy()
		end
	end
end

local clickConn
local function buildCategory(category, container)
	clearList(container)
	local folder = shopFolder:FindFirstChild(category)
	if not folder then return end

	local items = folder:GetChildren()
	table.sort(items, function(a, b)
		local aCost = a:FindFirstChild("Cost") and a.Cost.Value or 0
		local bCost = b:FindFirstChild("Cost") and b.Cost.Value or 0
		return aCost < bCost
	end)

	for _, shopItem in ipairs(items) do
		local name     = shopItem.Name
		local template = templates:FindFirstChild(name)
		if not template then continue end

		local btn = itemTemplate:Clone()
		btn.Name    = name
		btn.Visible = true
		btn.Parent  = container

		local rar = template:FindFirstChild("Rarity") and template.Rarity.Value or "Basic"
		btn.BackgroundColor3 = rarityColor[rar] or rarityColor.Basic

		local img    = btn:WaitForChild("PreviewImage")
		local iconId = template:FindFirstChild("IconID")
		img.Image    = iconId and "rbxassetid://"..iconId.Value or ""

		btn:WaitForChild("NameLabel").Text = name

		btn.MouseButton1Click:Connect(function()
			details.Visible = true

			local bigImg         = details:WaitForChild("BigImage")
			bigImg.Image        = iconId and "rbxassetid://"..iconId.Value or ""
			details:WaitForChild("ItemName"   ).Text = name
			details:WaitForChild("Description").Text = template:FindFirstChild("Description") and template.Description.Value or ""

			local actionBtn       = details:WaitForChild("ActionButton")
			local actionTextLabel = actionBtn:WaitForChild("TextLabel")
			if clickConn then clickConn:Disconnect() end

			if inv:FindFirstChild(name) then
				local equipped = (category=="Ranged" and eqr.Value) or eqm.Value
				if equipped == name then
					actionTextLabel.Text = "Equipped"
					actionBtn.Active     = false
				else
					actionTextLabel.Text = "Equip"
					actionBtn.Active     = true
					clickConn            = actionBtn.MouseButton1Click:Connect(function()
						equipRemote:FireServer(category, name)
						actionTextLabel.Text = "Equipped"
						actionBtn.Active     = false
					end)
				end
			else
				local cost = shopItem:FindFirstChild("Cost") and shopItem.Cost.Value or 0
				actionTextLabel.Text = "Buy ("..cost.."c)"
				actionBtn.Active     = true
				clickConn            = actionBtn.MouseButton1Click:Connect(function()
					-- purchase AND immediately equip
					purchaseRemote:FireServer(category, name)
					equipRemote:FireServer(category, name)
					actionTextLabel.Text = "Equipped"
					actionBtn.Active     = false
				end)
			end
		end)
	end
end

openBtn.MouseButton1Click:Connect(function()
	buildCategory("Ranged", rangedList)
	buildCategory("Melee",  meleeList)
	shopFrame.Visible = true
	openBtn.Visible   = false
end)

closeBtn.MouseButton1Click:Connect(function()
	shopFrame.Visible = false
	openBtn.Visible   = true
end)

rangedTab.MouseButton1Click:Connect(function()
	rangedList.Visible = true
	meleeList.Visible  = false
end)

meleeTab.MouseButton1Click:Connect(function()
	rangedList.Visible = false
	meleeList.Visible  = true
end)

startLobbyEvt.OnClientEvent:Connect(function()
	if not lobbyInitialized then
		lobbyInitialized   = true
		buildCategory("Ranged", rangedList)
		buildCategory("Melee",  meleeList)
		openBtn.Visible    = true
		shopFrame.Visible  = false
	end
end)

beginRoundEvt.OnClientEvent:Connect(function()
	lobbyInitialized   = false
	shopFrame.Visible  = false
	openBtn.Visible    = false
end)

purchaseRemote.OnClientEvent:Connect(function(ok, itemName)
	if not ok then return end
	if itemName and not inv:FindFirstChild(itemName) then
		local v = Instance.new("BoolValue")
		v.Name   = itemName
		v.Value  = true
		v.Parent = inv
	end
	buildCategory("Ranged", rangedList)
	buildCategory("Melee",  meleeList)
end)

equipRemote.OnClientEvent:Connect(function(ok, category, itemName)
	if not ok then return end
	if itemName then
		if category == "Ranged" then
			eqr.Value = itemName
		else
			eqm.Value = itemName
		end
	end
	buildCategory(category, category == "Ranged" and rangedList or meleeList)
end)

-- initial render
buildCategory("Ranged", rangedList)
buildCategory("Melee",  meleeList)
