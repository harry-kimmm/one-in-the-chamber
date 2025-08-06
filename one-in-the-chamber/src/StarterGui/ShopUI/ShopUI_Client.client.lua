-- ShopUI_Client.lua  (StarterGui → ShopUI → ShopUI_Client.lua)

local RS           = game:GetService("ReplicatedStorage")
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local pl           = Players.LocalPlayer

-- Remotes
local rem        = RS:WaitForChild("GameRemotes")
local buyR       = rem:WaitForChild("PurchaseItem")
local eqR        = rem:WaitForChild("EquipItem")
local equipRes   = rem:WaitForChild("EquipResult")
local openCrate  = rem:WaitForChild("OpenCrate")
local crateRes   = rem:WaitForChild("CrateResult")

-- Data
local shopF    = RS:WaitForChild("Shop")
local tmplRoot = RS:WaitForChild("ToolTemplates")

-- UI refs
local ui            = script.Parent
local btnShop       = ui:WaitForChild("OpenShopButton")
local btnInv        = ui:WaitForChild("OpenInvButton")
local purchaseSound = ui:WaitForChild("PurchaseSound")
local errorSound    = ui:WaitForChild("ErrorSound")

-- ensure both sounds are ready
purchaseSound.Volume = purchaseSound.Volume or 1
purchaseSound.Looped = false
errorSound.Volume    = errorSound.Volume or 1
errorSound.Looped    = false

local sFrame        = ui:WaitForChild("ShopFrame")
local sClose        = sFrame:WaitForChild("CloseButton")
local sRT           = sFrame:WaitForChild("RangedTab")
local sMT           = sFrame:WaitForChild("MeleeTab")
local sCT           = sFrame:WaitForChild("CratesTab")
local sRL           = sFrame:WaitForChild("RangedList")
local sML           = sFrame:WaitForChild("MeleeList")
local sCL           = sFrame:WaitForChild("CratesList")
local sDet          = sFrame:WaitForChild("ShopDetailsFrame")
local sMsg          = sDet:WaitForChild("FeedbackLabel"); sMsg.Visible = false
local shopTemplate  = sFrame:WaitForChild("ItemTemplate"); shopTemplate.Visible = false

local iFrame        = ui:WaitForChild("InvFrame")
local iClose        = iFrame:WaitForChild("CloseInvButton")
local iRT           = iFrame:WaitForChild("InvRangedTab")
local iMT           = iFrame:WaitForChild("InvMeleeTab")
local iRL           = iFrame:WaitForChild("InvRangedList")
local iML           = iFrame:WaitForChild("InvMeleeList")
local iDet          = iFrame:WaitForChild("InvDetailsFrame")
local iMsg          = iDet:WaitForChild("FeedbackLabel"); iMsg.Visible = false
local invTemplate   = iFrame:WaitForChild("ItemTemplate"); invTemplate.Visible = false

local spinnerF      = ui:WaitForChild("CrateSpinnerFrame")
local reel          = spinnerF:WaitForChild("Reel")
local reelLayout    = reel:WaitForChild("UIListLayout")
local spinTpl       = reel:WaitForChild("ItemTemplate"); spinTpl.Visible = false
local receivedLbl   = spinnerF:WaitForChild("ReceivedLabel"); receivedLbl.Visible = false

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

-- State
local spinning = false
local buyConn, eqConn

-- Helpers
local function clear(frame)
	for _,c in ipairs(frame:GetChildren()) do
		if c:IsA("TextButton") and c~=shopTemplate and c~=invTemplate and c~=spinTpl then
			c:Destroy()
		end
	end
end

local function showMessage(lbl, txt)
	lbl.Text = txt
	lbl.Visible = true
	task.delay(0.3, function() lbl.Visible = false end)
end

-- reset & play error
local function playError()
	errorSound:Stop()
	errorSound.TimePosition = 0
	errorSound:Play()
end

-- reset & play purchase
local function playPurchase()
	purchaseSound:Stop()
	purchaseSound.TimePosition = 0
	purchaseSound:Play()
end

local function makeBtn(parent, name, tmpl, tpl)
	local b = tpl:Clone()
	b.Name, b.Visible, b.Parent = name, true, parent
	b.BackgroundColor3 = rc[(tmpl.Rarity and tmpl.Rarity.Value) or "Basic"]
	b.PreviewImage.Image = tmpl.IconID and ("rbxassetid://"..tmpl.IconID.Value) or ""
	b.NameLabel.Text = name
	return b
end

-- Build shop (ranged & melee)
local function buildShop(cat, list)
	clear(list)
	for _,v in ipairs(shopF[cat]:GetChildren()) do
		local tmpl = tmplRoot[cat]:FindFirstChild(v.Name)
		if not tmpl then continue end

		local btn = makeBtn(list, v.Name, tmpl, shopTemplate)
		btn.MouseButton1Click:Connect(function()
			if spinning then return end
			sDet.Visible, sMsg.Visible = true, false
			sDet.BigImage.Image   = btn.PreviewImage.Image
			sDet.ItemName.Text    = v.Name
			sDet.Description.Text = (tmpl.Description and tmpl.Description.Value) or ""

			local AB = sDet:WaitForChild("ActionButton")
			local AL = AB.TextLabel
			if buyConn then buyConn:Disconnect() end
			AB.Active = true

			local cost = v:FindFirstChild("Cost") and v.Cost.Value or 0

			if inv:FindFirstChild(v.Name) then
				AL.Text = "Owned"; AB.Active = false
			else
				AL.Text = "Buy ("..cost.."c)"
				buyConn = AB.MouseButton1Click:Connect(function()
					if spinning or inv:FindFirstChild(v.Name) then return end
					if pl.Coins.Value < cost then
						showMessage(sMsg, "Can't afford")
						playError()
						return
					end
					AB.Active = false
					buyR:FireServer(cat, v.Name)
				end)
			end
		end)
	end
end

-- Build crates
local function buildCrates()
	clear(sCL)
	for _,c in ipairs(shopF.Crates:GetChildren()) do
		local fakeT = { Rarity={Value="Basic"}, IconID={Value=c.IconID and c.IconID.Value or ""} }
		local btn = makeBtn(sCL, c.Name, fakeT, shopTemplate)
		btn.MouseButton1Click:Connect(function()
			if spinning then return end
			sDet.Visible, sMsg.Visible = true, false
			sDet.BigImage.Image   = btn.PreviewImage.Image
			sDet.ItemName.Text    = c.Name

			local cost = c:FindFirstChild("Cost") and c.Cost.Value or 0
			sDet.Description.Text = "Opens for "..cost.."c"

			local AB = sDet:WaitForChild("ActionButton")
			local AL = AB.TextLabel
			if buyConn then buyConn:Disconnect() end
			AB.Active = true
			AL.Text = "Open ("..cost.."c)"

			buyConn = AB.MouseButton1Click:Connect(function()
				if spinning then return end
				if pl.Coins.Value < cost then
					showMessage(sMsg, "Can't afford")
					playError()
					return
				end
				AB.Active = false
				openCrate:FireServer(c.Name)
			end)
		end)
	end
end

-- Build inventory (equip only)
local function buildInv(cat, list)
	clear(list)
	for _,v in ipairs(inv:GetChildren()) do
		if not v.Value then continue end
		local tmpl = tmplRoot[cat]:FindFirstChild(v.Name)
		if not tmpl then continue end

		local btn = makeBtn(list, v.Name, tmpl, invTemplate)
		btn.MouseButton1Click:Connect(function()
			if spinning then return end
			iDet.Visible, iMsg.Visible = true, false
			iDet.BigImage.Image   = btn.PreviewImage.Image
			iDet.ItemName.Text    = v.Name
			iDet.Description.Text = (tmpl.Description and tmpl.Description.Value) or ""

			local AB = iDet:WaitForChild("ActionButton")
			local AL = AB.TextLabel
			if eqConn then eqConn:Disconnect() end
			AB.Active = true

			local isEq = (cat=="Ranged" and eqRng.Value==v.Name)
				or (cat=="Melee"  and eqMlv.Value==v.Name)
			if isEq then
				AL.Text = "Equipped"; AB.Active = false
			else
				AL.Text = "Equip"
				eqConn = AB.MouseButton1Click:Connect(function()
					if not spinning then eqR:FireServer(cat, v.Name) end
				end)
			end
		end)
	end
end

-- Spinner animation
local function buildSpinner(drops, won)
	spinning = true
	sFrame.Visible = false
	iFrame.Visible = false

	clear(reel)
	reel.CanvasPosition = Vector2.new(0,0)

	local loops = 5
	local seq = {}
	for i=1,loops do
		for _,d in ipairs(drops) do seq[#seq+1] = d end
	end
	local mid = math.ceil(#seq/2)
	local wonData
	for _,d in ipairs(drops) do if d.Name==won then wonData=d break end end
	if wonData then table.insert(seq, mid, wonData) end

	for idx,d in ipairs(seq) do
		local b = spinTpl:Clone()
		b.Visible     = true
		b.Parent      = reel
		b.LayoutOrder = idx
		b.PreviewImage.Image = (d.IconID~="" and "rbxassetid://"..d.IconID) or ""
		b.BackgroundColor3   = rc[d.Rarity] or rc.Basic
	end

	reelLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Wait()
	reel.CanvasSize = UDim2.new(0, reelLayout.AbsoluteContentSize.X, 0, 0)

	local slotW = spinTpl.AbsoluteSize.X
	local fw    = spinnerF.AbsoluteSize.X
	local target = slotW*(mid-1) - (fw/2 - slotW/2)
	local tween = TweenService:Create(reel, TweenInfo.new(3,Enum.EasingStyle.Cubic), {
		CanvasPosition = Vector2.new(target,0)
	})

	purchaseSound:Play()
	spinnerF.Visible = true
	tween:Play(); tween.Completed:Wait()

	receivedLbl.Text    = "Received "..won
	receivedLbl.TextColor3 = rc[wonData.Rarity] or rc.Basic
	receivedLbl.Visible = true

	task.delay(1, function()
		spinnerF.Visible     = false
		receivedLbl.Visible  = false
		clear(reel)
		spinning = false
		buildInv("Ranged", iRL)
		buildInv("Melee",  iML)
	end)
end

-- Remote listeners
crateRes.OnClientEvent:Connect(function(ok, _, won, drops)
	if ok then
		buildSpinner(drops, won)
	end
end)

buyR.OnClientEvent:Connect(function(ok, itemName)
	if ok then
		playPurchase()
		if sDet.Visible and sDet.ItemName.Text == itemName then
			local AB, AL = sDet:WaitForChild("ActionButton"), sDet.ActionButton.TextLabel
			AL.Text, AB.Active = "Owned", false
		end
		buildShop("Ranged", sRL)
		buildShop("Melee",  sML)
	end
end)

equipRes.OnClientEvent:Connect(function(ok, cat, itemName)
	if ok then
		if iDet.Visible and iDet.ItemName.Text == itemName then
			local AB, AL = iDet:WaitForChild("ActionButton"), iDet.ActionButton.TextLabel
			AL.Text, AB.Active = "Equipped", false
		end
		buildInv("Ranged", iRL)
		buildInv("Melee",  iML)
	end
end)

-- UI wiring
sFrame.Visible = false
iFrame.Visible = false

btnShop.MouseButton1Click:Connect(function()
	if spinning then return end
	sFrame.Visible = true
	iFrame.Visible = false
	buildShop("Ranged", sRL)
	buildShop("Melee",  sML)
end)

sClose.MouseButton1Click:Connect(function()
	sFrame.Visible = false
end)

btnInv.MouseButton1Click:Connect(function()
	if spinning then return end
	iFrame.Visible = true
	sFrame.Visible = false
	buildInv("Ranged", iRL)
	buildInv("Melee",  iML)
end)

iClose.MouseButton1Click:Connect(function()
	iFrame.Visible = false
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

iRT.MouseButton1Click:Connect(function()
	iRL.Visible, iML.Visible = true, false
end)
iMT.MouseButton1Click:Connect(function()
	iRL.Visible, iML.Visible = false, true
end)

-- Initial builds
buildShop("Ranged", sRL)
buildShop("Melee",  sML)
