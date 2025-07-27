local RS           = game:GetService("ReplicatedStorage")
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local pl           = Players.LocalPlayer

local rem       = RS:WaitForChild("GameRemotes")
local buyR      = rem:WaitForChild("PurchaseItem")
local eqR       = rem:WaitForChild("EquipItem")
local openCrate = rem:WaitForChild("OpenCrate")
local crateRes  = rem:WaitForChild("CrateResult")
local sellItem  = rem:WaitForChild("SellItem")
local sellRes   = rem:WaitForChild("SellResult")
local eLobby    = rem:WaitForChild("StartLobby")
local eRound    = rem:WaitForChild("BeginRound")

local shopF     = RS:WaitForChild("Shop")
local tmplRoot  = RS:WaitForChild("ToolTemplates")

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

local iFrame   = ui:WaitForChild("InvFrame")
local iClose   = iFrame:WaitForChild("CloseInvButton")
local iRT      = iFrame:WaitForChild("InvRangedTab")
local iMT      = iFrame:WaitForChild("InvMeleeTab")
local iRL      = iFrame:WaitForChild("InvRangedList")
local iML      = iFrame:WaitForChild("InvMeleeList")
local iDet     = iFrame:WaitForChild("InvDetailsFrame")

local spinnerF = ui:WaitForChild("CrateSpinnerFrame")
local reel     = spinnerF:WaitForChild("Reel")
reel.ScrollingDirection         = Enum.ScrollingDirection.X
reel.ScrollingEnabled           = false
reel.ScrollBarImageTransparency = 1
reel.ScrollBarThickness         = 0
local reelLayout = reel:WaitForChild("UIListLayout")

local spinTpl       = reel:WaitForChild("ItemTemplate"); spinTpl.Visible = false
local receivedLabel = spinnerF:WaitForChild("ReceivedLabel"); receivedLabel.Visible = false

local itemT      = sFrame:WaitForChild("ItemTemplate"); itemT.Visible = false

local inv        = pl:WaitForChild("Inventory")
local eqRng      = pl:WaitForChild("EquippedRanged")
local eqMlv      = pl:WaitForChild("EquippedMelee")

local rc = {
	Basic     = Color3.fromRGB(200,200,200),
	Common    = Color3.fromRGB(170,170,170),
	Uncommon  = Color3.fromRGB(100,255,100),
	Rare      = Color3.fromRGB(100,150,255),
	Epic      = Color3.fromRGB(200,100,255),
	Legendary = Color3.fromRGB(255,200,100),
}

local spinning = false

local function clear(frame)
	for _,c in ipairs(frame:GetChildren()) do
		if c:IsA("TextButton") and c~=itemT and c~=spinTpl then
			c:Destroy()
		end
	end
end

local function makeBtn(parent,name,tmpl)
	local b = itemT:Clone()
	b.Visible, b.Parent, b.Name = true, parent, name
	b.BackgroundColor3 = rc[tmpl:FindFirstChild("Rarity") and tmpl.Rarity.Value or "Basic"]
	b.PreviewImage.Image = tmpl:FindFirstChild("IconID")
		and "rbxassetid://"..tmpl.IconID.Value or ""
	b.NameLabel.Text = name
	return b
end

local function buildShop(cat,list)
	clear(list)
	for _,v in ipairs(shopF[cat]:GetChildren()) do
		local nm,tmpl = v.Name, tmplRoot[cat]:FindFirstChild(v.Name)
		if not tmpl then continue end
		local b = makeBtn(list,nm,tmpl)
		b.MouseButton1Click:Connect(function()
			if spinning then return end
			sDet.Visible      = true
			sDet.BigImage.Image  = b.PreviewImage.Image
			sDet.ItemName.Text   = nm
			sDet.Description.Text = tmpl:FindFirstChild("Description")
				and tmpl.Description.Value or ""
			local AB,AL = sDet.ActionButton, sDet.ActionButton.TextLabel
			if _G.sConn then _G.sConn:Disconnect() end
			AB.Active, AL.Text = true, ""
			if inv:FindFirstChild(nm) then
				AL.Text,AB.Active,_G.sConn = "Owned",false,nil
			else
				AL.Text = "Buy ("..v.Cost.Value.."c)"
				_G.sConn = AB.MouseButton1Click:Connect(function()
					if spinning then return end
					AB.Active = false
					buyR:FireServer(cat,nm)
				end)
			end
		end)
	end
end

local function buildCrates()
	clear(sCL)
	for _,c in ipairs(shopF.Crates:GetChildren()) do
		local nm   = c.Name
		local cost = c:FindFirstChild("Cost") and c.Cost.Value or 0
		local icon = c:FindFirstChild("IconID") and c.IconID.Value or ""
		local b = itemT:Clone()
		b.Name,b.Visible,b.Parent = nm,true,sCL
		b.BackgroundColor3        = rc.Basic
		b.PreviewImage.Image      = icon~="" and "rbxassetid://"..icon or ""
		b.NameLabel.Text          = nm
		b.MouseButton1Click:Connect(function()
			if spinning then return end
			sDet.Visible      = true
			sDet.BigImage.Image  = b.PreviewImage.Image
			sDet.ItemName.Text   = nm
			sDet.Description.Text = "Opens for "..cost.." coins"
			local AB,AL = sDet.ActionButton, sDet.ActionButton.TextLabel
			if _G.sConn then _G.sConn:Disconnect() end
			AB.Active,AL.Text = true, "Open ("..cost.."c)"
			_G.sConn = AB.MouseButton1Click:Connect(function()
				if spinning then return end
				AB.Active = false
				openCrate:FireServer(nm)
			end)
		end)
	end
end

local function buildInv(cat,list)
	clear(list)
	for _,v in ipairs(inv:GetChildren()) do
		if not v.Value then continue end
		local nm,tmpl = v.Name, tmplRoot[cat]:FindFirstChild(v.Name)
		if not tmpl then continue end
		local b = makeBtn(list,nm,tmpl)
		b.MouseButton1Click:Connect(function()
			if spinning then return end
			iDet.Visible      = true
			iDet.BigImage.Image  = b.PreviewImage.Image
			iDet.ItemName.Text   = nm
			iDet.Description.Text = tmpl:FindFirstChild("Description")
				and tmpl.Description.Value or ""
			local AB,AL      = iDet.ActionButton, iDet.ActionButton.TextLabel
			local sellB,sellL = iDet:WaitForChild("SellButton"), iDet.SellButton.TextLabel
			if _G.iConn then _G.iConn:Disconnect() end
			AB.Active,AL.Text = true,""
			sellB.Visible     = false
			if (cat=="Ranged" and eqRng.Value==nm)
				or (cat=="Melee"  and eqMlv.Value==nm) then
				AL.Text,AB.Active = "Equipped",false
			else
				AL.Text = "Equip"
				_G.iConn = AB.MouseButton1Click:Connect(function()
					AB.Active = false
					eqR:FireServer(cat,nm)
				end)
			end
			if v:FindFirstChild("FromCrate") then
				local rar    = tmpl:FindFirstChild("Rarity") and tmpl.Rarity.Value or "Common"
				local prices = {Common=50,Uncommon=125,Rare=450,Epic=750,Legendary=1000}
				sellL.Text = "Sell ("..(prices[rar] or 0).."c)"
				sellB.Active, sellB.Visible = true,true
				sellB.MouseButton1Click:Once(function()
					sellItem:FireServer(nm)
				end)
			end
		end)
	end
end

-- Build spinner so won item lands in the true middle slot
local function buildSpinner(drops,won)
	spinning = true
	clear(reel)
	reel.CanvasPosition = Vector2.new(0,0)

	local loops       = 5
	local dropsCount  = #drops
	local totalSlots  = loops * dropsCount + 1
	local middleIndex = math.ceil(totalSlots/2)

	local seq = {}
	for i=1,loops do
		for _,d in ipairs(drops) do
			table.insert(seq,d)
		end
	end
	local wonData
	for _,d in ipairs(drops) do
		if d.Name==won then wonData=d; break end
	end
	if wonData then
		table.insert(seq, middleIndex, wonData)
	end

	for idx,d in ipairs(seq) do
		local b = spinTpl:Clone()
		b.Visible     = true
		b.Parent      = reel
		b.LayoutOrder = idx
		b.PreviewImage.Image = (d.IconID~="" and "rbxassetid://"..d.IconID) or ""
		b.BackgroundColor3   = rc[d.Rarity] or rc.Basic
		b.Size = spinTpl.Size
	end

	reelLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Wait()
	reel.CanvasSize = UDim2.new(0,reelLayout.AbsoluteContentSize.X,0,0)

	local slotW     = spinTpl.AbsoluteSize.X
	local frameW    = spinnerF.AbsoluteSize.X
	local targetX   = slotW*(middleIndex-1) - (frameW/2 - slotW/2)

	local tween = TweenService:Create(
		reel,
		TweenInfo.new(3,Enum.EasingStyle.Cubic),
		{ CanvasPosition = Vector2.new(targetX,0) }
	)
	tween:Play(); tween.Completed:Wait()

	receivedLabel.Text = "Received "..won
	receivedLabel.TextColor3 = (wonData and rc[wonData.Rarity]) or rc.Basic
	receivedLabel.Visible = true

	task.delay(1, function()
		spinnerF.Visible      = false
		receivedLabel.Visible = false
		buildInv("Ranged",iRL)
		buildInv("Melee", iML)
		spinning = false
	end)
end

crateRes.OnClientEvent:Connect(function(ok,crateName,won,drops)
	if not ok then return end

	spinnerF.Visible      = true
	receivedLabel.Visible = false
	buildSpinner(drops,won)
end)

-- Tab & callback wiring
btnShop.MouseButton1Click:Connect(function()
	iFrame.Visible=false; sCL.Visible=false
	buildShop("Ranged",sRL); buildShop("Melee",sML)
	sRL.Visible=true; sFrame.Visible=true
end)
sClose.MouseButton1Click:Connect(function() sFrame.Visible=false end)
sRT.MouseButton1Click:Connect(function() sRL.Visible=true; sML.Visible=false; sCL.Visible=false end)
sMT.MouseButton1Click:Connect(function() sRL.Visible=false; sML.Visible=true; sCL.Visible=false end)
sCT.MouseButton1Click:Connect(function() sRL.Visible=false; sML.Visible=false; sCL.Visible=true; buildCrates() end)

btnInv.MouseButton1Click:Connect(function()
	sFrame.Visible=false
	buildInv("Ranged",iRL); buildInv("Melee",iML)
	iFrame.Visible=true
end)
iClose.MouseButton1Click:Connect(function() iFrame.Visible=false end)
iRT.MouseButton1Click:Connect(function() iRL.Visible=true; iML.Visible=false end)
iMT.MouseButton1Click:Connect(function() iRL.Visible=false; iML.Visible=true end)

eLobby.OnClientEvent:Connect(function() btnShop.Visible=true; btnInv.Visible=true end)
eRound.OnClientEvent:Connect(function()
	btnShop.Visible=false; btnInv.Visible=false
	sFrame.Visible=false; iFrame.Visible=false
end)

buyR.OnClientEvent:Connect(function(ok,nm)
	if ok and nm then
		buildShop("Ranged",sRL); buildShop("Melee",sML)
		if sDet.Visible and sDet.ItemName.Text==nm then
			local AB=sDet.ActionButton
			AB.TextLabel.Text, AB.Active = "Owned", false
			if _G.sConn then _G.sConn:Disconnect(); _G.sConn=nil end
		end
	end
end)

eqR.OnClientEvent:Connect(function(ok,cat,nm)
	if ok and nm then
		if cat=="Ranged" then eqRng.Value=nm else eqMlv.Value=nm end
	end
	buildInv("Ranged",iRL); buildInv("Melee",iML)
	if iDet.Visible and iDet.ItemName.Text==nm then
		local AB=iDet.ActionButton
		AB.TextLabel.Text, AB.Active = "Equipped", false
		if _G.iConn then _G.iConn:Disconnect(); _G.iConn=nil end
	end
end)

sellRes.OnClientEvent:Connect(function(ok,nm)
	if not ok then return end
	buildInv("Ranged",iRL); buildInv("Melee",iML)
end)

buildShop("Ranged",sRL)
buildShop("Melee",sML)
