-- StarterGui → ShopUI → ShopUI_Client.lua

local RS           = game:GetService("ReplicatedStorage")
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local pl           = Players.LocalPlayer

-- Remotes
local rem       = RS:WaitForChild("GameRemotes")
local buyR      = rem:WaitForChild("PurchaseItem")
local eqR       = rem:WaitForChild("EquipItem")
local openCrate = rem:WaitForChild("OpenCrate")
local crateRes  = rem:WaitForChild("CrateResult")
local sellItem  = rem:WaitForChild("SellItem")
local sellRes   = rem:WaitForChild("SellResult")
local eLobby    = rem:WaitForChild("StartLobby")
local eRound    = rem:WaitForChild("BeginRound")

-- Data folders
local shopF    = RS:WaitForChild("Shop")
local tmplRoot = RS:WaitForChild("ToolTemplates")

-- UI references
local ui       = script.Parent
local btnShop  = ui:WaitForChild("OpenShopButton")
local btnInv   = ui:WaitForChild("OpenInvButton")

local sFrame   = ui:WaitForChild("ShopFrame")
local sClose   = sFrame:WaitForChild("CloseButton")
local sRT      = sFrame:WaitForChild("RangedTab")
local sMT      = sFrame:WaitForChild("MeleeTab")
local sCT      = sFrame:WaitForChild("CratesTab")
local sRL      = sFrame:WaitForChild("RangedList")
local sML      = sFrame:WaitForChild("MeleeList")
local sCL      = sFrame:WaitForChild("CratesList")
local sDet     = sFrame:WaitForChild("ShopDetailsFrame")
local sMsg     = sDet:WaitForChild("FeedbackLabel"); sMsg.Visible = false

local iFrame   = ui:WaitForChild("InvFrame")
local iClose   = iFrame:WaitForChild("CloseInvButton")
local iRT      = iFrame:WaitForChild("InvRangedTab")
local iMT      = iFrame:WaitForChild("InvMeleeTab")
local iRL      = iFrame:WaitForChild("InvRangedList")
local iML      = iFrame:WaitForChild("InvMeleeList")
local iDet     = iFrame:WaitForChild("InvDetailsFrame")
local iMsg     = iDet:WaitForChild("FeedbackLabel"); iMsg.Visible = false

local spinnerF = ui:WaitForChild("CrateSpinnerFrame")
local reel     = spinnerF:WaitForChild("Reel")
reel.ScrollingDirection         = Enum.ScrollingDirection.X
reel.ScrollingEnabled           = false
reel.ScrollBarImageTransparency = 1
reel.ScrollBarThickness         = 0
local reelLayout   = reel:WaitForChild("UIListLayout")
local spinTpl      = reel:WaitForChild("ItemTemplate"); spinTpl.Visible = false
local receivedLabel = spinnerF:WaitForChild("ReceivedLabel"); receivedLabel.Visible = false

local itemT    = sFrame:WaitForChild("ItemTemplate"); itemT.Visible = false

-- Player data
local inv   = pl:WaitForChild("Inventory")
local eqRng = pl:WaitForChild("EquippedRanged")
local eqMlv = pl:WaitForChild("EquippedMelee")

-- Rarity colors
local rc = {
	Basic     = Color3.fromRGB(200,200,200),
	Common    = Color3.fromRGB(170,170,170),
	Uncommon  = Color3.fromRGB(100,255,100),
	Rare      = Color3.fromRGB(100,150,255),
	Epic      = Color3.fromRGB(200,100,255),
	Legendary = Color3.fromRGB(255,200,100),
}

local spinning = false

-- Clears children buttons except templates
local function clear(frame)
	for _,c in ipairs(frame:GetChildren()) do
		if c:IsA("TextButton") and c~=itemT and c~=spinTpl then
			c:Destroy()
		end
	end
end

-- Shows a brief feedback label
local function showMessage(lbl, txt)
	lbl.Text = txt
	lbl.Visible = true
	task.delay(0.3, function() lbl.Visible = false end)
end

-- Clones the item template and fills in name/icon/rarity color
local function makeBtn(parent, name, tmpl)
	local b = itemT:Clone()
	b.Name, b.Visible, b.Parent = name, true, parent
	b.BackgroundColor3 = rc[(tmpl.Rarity and tmpl.Rarity.Value) or "Basic"]
	b.PreviewImage.Image = tmpl.IconID and ("rbxassetid://"..tmpl.IconID.Value) or ""
	b.NameLabel.Text = name
	return b
end

-- Build the Shop grids (Ranged/Melee)
local function buildShop(cat, list)
	clear(list)
	for _,v in ipairs(shopF[cat]:GetChildren()) do
		local tmpl = tmplRoot[cat]:FindFirstChild(v.Name)
		if not tmpl then continue end
		local btn = makeBtn(list, v.Name, tmpl)
		btn.MouseButton1Click:Connect(function()
			if spinning then return end
			sDet.Visible = true
			sMsg.Visible = false
			sDet.BigImage.Image   = btn.PreviewImage.Image
			sDet.ItemName.Text    = v.Name
			sDet.Description.Text = tmpl.Description and tmpl.Description.Value or ""
			local AB, AL = sDet.ActionButton, sDet.ActionButton.TextLabel
			if _G.sConn then _G.sConn:Disconnect() end
			AB.Active = true

			local cost = v:FindFirstChild("Cost") and v.Cost.Value or 0

			if inv:FindFirstChild(v.Name) then
				AL.Text = "Owned"
				AB.Active = false
			else
				AL.Text = "Buy ("..cost.."c)"
				_G.sConn = AB.MouseButton1Click:Connect(function()
					if pl.Coins.Value < cost then
						showMessage(sMsg, "Can't afford")
						return
					end
					AB.Active = false
					buyR:FireServer(cat, v.Name)
				end)
			end
		end)
	end
end

-- Build the Crates grid
local function buildCrates()
	clear(sCL)
	for _,c in ipairs(shopF.Crates:GetChildren()) do
		local btn = makeBtn(sCL, c.Name, { Rarity={Value="Basic"}, IconID={Value=c.IconID and c.IconID.Value or ""} })
		btn.MouseButton1Click:Connect(function()
			if spinning then return end
			sDet.Visible = true
			sMsg.Visible = false
			sDet.BigImage.Image   = btn.PreviewImage.Image
			sDet.ItemName.Text    = c.Name
			sDet.Description.Text = "Opens for "..(c.Cost and c.Cost.Value or 0).."c"
			local AB, AL = sDet.ActionButton, sDet.ActionButton.TextLabel
			if _G.sConn then _G.sConn:Disconnect() end
			AB.Active, AL.Text = true, "Open ("..c.Cost.Value.."c)"
			_G.sConn = AB.MouseButton1Click:Connect(function()
				if spinning then return end
				AB.Active = false
				openCrate:FireServer(c.Name)
			end)
		end)
	end
end

-- Build the Inventory grids
local function buildInv(cat, list)
	clear(list)
	for _,v in ipairs(inv:GetChildren()) do
		if not v.Value then continue end
		local tmpl = tmplRoot[cat]:FindFirstChild(v.Name)
		if not tmpl then continue end
		local btn = makeBtn(list, v.Name, tmpl)
		btn.MouseButton1Click:Connect(function()
			if spinning then return end
			iDet.Visible = true
			iMsg.Visible = false
			iDet.BigImage.Image   = btn.PreviewImage.Image
			iDet.ItemName.Text    = v.Name
			iDet.Description.Text = tmpl.Description and tmpl.Description.Value or ""
			local AB, AL = iDet.ActionButton, iDet.ActionButton.TextLabel
			local sellB, sellL = iDet:WaitForChild("SellButton"), iDet.SellButton.TextLabel
			if _G.iConn then _G.iConn:Disconnect() end
			AB.Active = true

			-- Equip logic
			local isEq = (cat=="Ranged" and eqRng.Value==v.Name) or (cat=="Melee" and eqMlv.Value==v.Name)
			if isEq then
				AL.Text, AB.Active = "Equipped", false
			else
				AL.Text = "Equip"
				AB.Active = true
				AB.MouseButton1Click:Connect(function()
					eqR:FireServer(cat, v.Name)
				end)
			end

			-- Sell logic only for crate drops, and not the basic defaults
			if v:FindFirstChild("FromCrate") and not isEq then
				sellB.Visible = true
				local prices = {Common=50,Uncommon=125,Rare=450,Epic=750,Legendary=1000}
				local price = prices[tmpl.Rarity.Value] or 0
				sellL.Text = "Sell ("..price.."c)"
				sellB.MouseButton1Click:Connect(function()
					sellItem:FireServer(v)
				end)
			else
				sellB.Visible = false
			end
		end)
	end
end

-- Spinner animation (3s, center align)
local function buildSpinner(drops, won)
	spinning = true
	clear(reel)
	reel.CanvasPosition = Vector2.new(0,0)
	local loops = 5
	local dc    = #drops
	local total = loops * dc + 1
	local mid   = math.ceil(total/2)
	local seq = {}
	for i=1,loops do
		for _,d in ipairs(drops) do table.insert(seq, d) end
	end
	local wonData
	for _,d in ipairs(drops) do if d.Name==won then wonData=d; break end end
	if wonData then table.insert(seq, mid, wonData) end
	for idx,d in ipairs(seq) do
		local b = spinTpl:Clone()
		b.Visible     = true
		b.Parent      = reel
		b.LayoutOrder = idx
		b.PreviewImage.Image = d.IconID~="" and "rbxassetid://"..d.IconID or ""
		b.BackgroundColor3   = rc[d.Rarity] or rc.Basic
		b.Size = spinTpl.Size
	end
	reelLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Wait()
	reel.CanvasSize = UDim2.new(0, reelLayout.AbsoluteContentSize.X, 0, 0)
	local w = spinTpl.AbsoluteSize.X
	local fw= spinnerF.AbsoluteSize.X
	local tx= w*(mid-1) - (fw/2 - w/2)
	local tween = TweenService:Create(reel, TweenInfo.new(3, Enum.EasingStyle.Cubic), {CanvasPosition=Vector2.new(tx,0)})
	spinnerF.Visible      = true
	receivedLabel.Visible = false
	tween:Play(); tween.Completed:Wait()
	receivedLabel.Text      = "Received "..won
	receivedLabel.TextColor3= rc[wonData.Rarity] or rc.Basic
	receivedLabel.Visible   = true
	task.delay(1, function()
		spinnerF.Visible      = false
		receivedLabel.Visible = false
		-- only hide inventory detail on sell, not on equip
		buildInv("Ranged", iRL)
		buildInv("Melee",  iML)
		spinning = false
	end)
end

-- Remote event hookups

crateRes.OnClientEvent:Connect(function(ok, crateName, won, drops)
	if not ok then return end
	buildSpinner(drops, won)
end)

buyR.OnClientEvent:Connect(function(ok, nm)
	if ok and sDet.Visible and sDet.ItemName.Text==nm then
		local AB = sDet.ActionButton
		AB.TextLabel.Text = "Owned"
		AB.Active = false
		if _G.sConn then _G.sConn:Disconnect(); _G.sConn = nil end
	end
	buildShop("Ranged", sRL)
	buildShop("Melee",  sML)
end)

eqR.OnClientEvent:Connect(function(ok, cat, nm)
	if ok then
		-- update only the detail button, keep detail open
		if iDet.Visible and iDet.ItemName.Text==nm then
			local AB = iDet.ActionButton
			AB.TextLabel.Text = "Equipped"
			AB.Active = false
		end
		buildInv("Ranged", iRL)
		buildInv("Melee",  iML)
	end
end)

sellRes.OnClientEvent:Connect(function(ok, nm, price)
	if ok then
		iDet.Visible = false
		buildInv("Ranged", iRL)
		buildInv("Melee",  iML)
	end
end)

-- UI wiring

btnShop.MouseButton1Click:Connect(function()
	if spinning then return end
	iFrame.Visible = false
	sCL.Visible    = false
	buildShop("Ranged", sRL)
	buildShop("Melee",  sML)
	sRL.Visible    = true
	sFrame.Visible = true
end)

sClose.MouseButton1Click:Connect(function()
	sFrame.Visible = false
end)

sRT.MouseButton1Click:Connect(function()
	sRL.Visible, sML.Visible, sCL.Visible = true, false, false
end)

sMT.MouseButton1Click:Connect(function()
	sRL.Visible, sML.Visible, sCL.Visible = false, true, false
end)

sCT.MouseButton1Click:Connect(function()
	if spinning then return end
	sRL.Visible, sML.Visible, sCL.Visible = false, false, true
	buildCrates()
end)

btnInv.MouseButton1Click:Connect(function()
	if spinning then return end
	sFrame.Visible = false
	buildInv("Ranged", iRL)
	buildInv("Melee",  iML)
	iFrame.Visible = true
end)

iClose.MouseButton1Click:Connect(function()
	iFrame.Visible = false
end)

iRT.MouseButton1Click:Connect(function()
	iRL.Visible, iML.Visible = true, false
end)

iMT.MouseButton1Click:Connect(function()
	iRL.Visible, iML.Visible = false, true
end)

eLobby.OnClientEvent:Connect(function()
	btnShop.Visible = true
	btnInv.Visible  = true
end)

eRound.OnClientEvent:Connect(function()
	btnShop.Visible = false
	btnInv.Visible  = false
	sFrame.Visible  = false
	iFrame.Visible  = false
end)

-- Initial builds
buildShop("Ranged", sRL)
buildShop("Melee",  sML)
