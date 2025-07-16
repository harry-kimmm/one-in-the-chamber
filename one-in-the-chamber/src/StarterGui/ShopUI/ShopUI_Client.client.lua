-- StarterGui/ShopUI/ShopUI_Client.lua

local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local player     = Players.LocalPlayer

-- Remotes
local remotes        = RS:WaitForChild("GameRemotes")
local purchaseRemote = remotes:WaitForChild("PurchaseItem")
local equipRemote    = remotes:WaitForChild("EquipItem")
local startLobbyEvt  = remotes:WaitForChild("StartLobby")
local beginRoundEvt  = remotes:WaitForChild("BeginRound")

-- Shop data
local shopFolder = RS:WaitForChild("Shop")

-- UI refs
local ui         = script.Parent
local openBtn    = ui:WaitForChild("OpenShopButton")
local shopFrame  = ui:WaitForChild("ShopFrame")
local closeBtn   = shopFrame:WaitForChild("CloseButton")
local rangedTab  = shopFrame:WaitForChild("RangedTab")
local meleeTab   = shopFrame:WaitForChild("MeleeTab")
local rangedList = shopFrame:WaitForChild("RangedList")
local meleeList  = shopFrame:WaitForChild("MeleeList")

-- Player stats
local inv   = player:WaitForChild("Inventory")
local eqr   = player:WaitForChild("EquippedRanged")
local eqm   = player:WaitForChild("EquippedMelee")
local coins = player:WaitForChild("Coins")

-- Flags so we only initialize once per lobby, and only close once per round
local lobbyInitialized = false
local roundClosed      = false

local function clear(list)
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
end

local function refreshList(cat, frame)
	clear(frame)
	-- default
	local defaultName = (cat=="Ranged") and "Gun" or "Sword"
	do
		local btn = Instance.new("TextButton")
		btn.Size, btn.Parent = UDim2.new(1,-4,0,30), frame
		local isEq = (cat=="Ranged" and eqr.Value==defaultName)
			or (cat=="Melee"  and eqm.Value==defaultName)
		btn.Text = defaultName .. (isEq and " — Equipped" or " — Default")
		btn.MouseButton1Click:Connect(function()
			equipRemote:FireServer(cat, defaultName)
		end)
	end
	-- cosmetics
	for _, item in ipairs(shopFolder[cat]:GetChildren()) do
		local cost = item:FindFirstChild("Cost") and item.Cost.Value or 0
		local owned= inv:FindFirstChild(item.Name)
		local btn  = Instance.new("TextButton")
		btn.Size, btn.Parent = UDim2.new(1,-4,0,30), frame
		local isEq = (cat=="Ranged" and eqr.Value==item.Name)
			or (cat=="Melee"  and eqm.Value==item.Name)
		if owned and owned.Value then
			btn.Text = item.Name .. (isEq and " — Equipped" or " — Owned")
			btn.MouseButton1Click:Connect(function()
				equipRemote:FireServer(cat, item.Name)
			end)
		else
			btn.Text = item.Name.." — "..cost.."c"
			btn.MouseButton1Click:Connect(function()
				purchaseRemote:FireServer(cat, item.Name)
			end)
		end
	end
end

purchaseRemote.OnClientEvent:Connect(function(ok,msg)
	if ok then
		refreshList("Ranged", rangedList)
		refreshList("Melee",  meleeList)
	else
		warn("Purchase failed:", msg)
	end
end)

equipRemote.OnClientEvent:Connect(function(ok,cat)
	if not ok then return end
	refreshList(cat, (cat=="Ranged" and rangedList or meleeList))
end)

-- tabs
rangedTab.MouseButton1Click:Connect(function()
	rangedList.Visible, meleeList.Visible = true, false
end)
meleeTab.MouseButton1Click:Connect(function()
	rangedList.Visible, meleeList.Visible = false, true
end)

-- open/close buttons
openBtn.MouseButton1Click:Connect(function()
	shopFrame.Visible, openBtn.Visible = true, false
end)
closeBtn.MouseButton1Click:Connect(function()
	shopFrame.Visible, openBtn.Visible = false, true
end)

-- only initialize shop on the very first lobby tick
startLobbyEvt.OnClientEvent:Connect(function(_)
	if lobbyInitialized then return end
	lobbyInitialized = true
	roundClosed      = false

	openBtn.Visible   = true
	shopFrame.Visible = false

	refreshList("Ranged", rangedList)
	refreshList("Melee",  meleeList)
	rangedList.Visible = true
	meleeList.Visible  = false
end)

-- only close shop once at the moment the round actually begins
beginRoundEvt.OnClientEvent:Connect(function()
	if roundClosed then return end
	shopFrame.Visible, openBtn.Visible = false, false
	roundClosed = true
	-- reset lobby flag so next match will re-open
	lobbyInitialized = false
end)
