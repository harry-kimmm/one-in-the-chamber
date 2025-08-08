-- StarterGui → ShopUI → ShopUI_Client.lua

local RS           = game:GetService("ReplicatedStorage")
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local pl           = Players.LocalPlayer

-- Remotes
local rem           = RS:WaitForChild("GameRemotes")
local buyR          = rem:WaitForChild("PurchaseItem")
local eqR           = rem:WaitForChild("EquipItem")
local equipRes      = rem:WaitForChild("EquipResult")
local openCrate     = rem:WaitForChild("OpenCrate")
local crateRes      = rem:WaitForChild("CrateResult")
local eLobby        = rem:WaitForChild("StartLobby")
local eBeginRound   = rem:WaitForChild("BeginRound")

-- Data roots
local shopF      = RS:WaitForChild("Shop")
local toolsRoot  = RS:WaitForChild("ToolTemplates") -- Ranged/Melee
local aurasRoot  = RS:WaitForChild("Auras")

-- UI root
local ui = script.Parent

-- sounds
local purchaseSound   = ui:WaitForChild("PurchaseSound")
local errorSound      = ui:WaitForChild("ErrorSound")
purchaseSound.Looped = false
errorSound.Looped    = false

-- helper: if you accidentally have duplicate tabs, pick a visible TextButton
local function pickTab(parent, name)
	local hits = {}
	for _,c in ipairs(parent:GetChildren()) do
		if c.Name == name and c:IsA("TextButton") then table.insert(hits, c) end
	end
	if #hits == 0 then
		return parent:WaitForChild(name) -- will error if truly missing
	elseif #hits == 1 then
		return hits[1]
	else
		-- prefer the visible one
		for _,b in ipairs(hits) do if b.Visible then return b end end
		return hits[1]
	end
end

-- Shop frame
local sFrame       = ui:WaitForChild("ShopFrame")
local sClose       = sFrame:WaitForChild("CloseButton")
local sRT          = pickTab(sFrame, "RangedTab")
local sMT          = pickTab(sFrame, "MeleeTab")
local sAT          = pickTab(sFrame, "AurasTab")
local sCT          = pickTab(sFrame, "CratesTab")
local sRL          = sFrame:WaitForChild("RangedList")
local sML          = sFrame:WaitForChild("MeleeList")
local sAL          = sFrame:WaitForChild("AurasList")
local sCL          = sFrame:WaitForChild("CratesList")
local sDet         = sFrame:WaitForChild("ShopDetailsFrame")
local sMsg         = sDet:WaitForChild("FeedbackLabel"); sMsg.Visible = false
local shopTemplate = sFrame:WaitForChild("ItemTemplate"); shopTemplate.Visible = false

-- Inventory frame
local iFrame       = ui:WaitForChild("InvFrame")
local iClose       = iFrame:WaitForChild("CloseInvButton")
local iRT          = pickTab(iFrame, "InvRangedTab")
local iMT          = pickTab(iFrame, "InvMeleeTab")
local iAT          = pickTab(iFrame, "InvAurasTab")
local iRL          = iFrame:WaitForChild("InvRangedList")
local iML          = iFrame:WaitForChild("InvMeleeList")
local iAL          = iFrame:WaitForChild("InvAurasList")
local iDet         = iFrame:WaitForChild("InvDetailsFrame")
local iMsg         = iDet:WaitForChild("FeedbackLabel"); iMsg.Visible = false
local invTemplate  = iFrame:WaitForChild("ItemTemplate"); invTemplate.Visible = false

-- Spinner
local spinnerF     = ui:WaitForChild("CrateSpinnerFrame")
local reel         = spinnerF:WaitForChild("Reel")
local reelLayout   = reel:WaitForChild("UIListLayout")
local spinTpl      = reel:WaitForChild("ItemTemplate"); spinTpl.Visible = false
local receivedLbl  = spinnerF:WaitForChild("ReceivedLabel"); receivedLbl.Visible = false

-- Player state
local inv     = pl:WaitForChild("Inventory")
local eqRng   = pl:WaitForChild("EquippedRanged")
local eqMlv   = pl:WaitForChild("EquippedMelee")
local eqAura  = pl:WaitForChild("EquippedAura")

-- Rarity palette
local rc = {
	Basic     = Color3.fromRGB(200,200,200),
	Common    = Color3.fromRGB(170,170,170),
	Uncommon  = Color3.fromRGB(100,255,100),
	Rare      = Color3.fromRGB(100,150,255),
	Epic      = Color3.fromRGB(200,100,255),
	Legendary = Color3.fromRGB(255,200,100),
}

-- Local state
local spinning = false
local buyConn, eqConn

-- ===== helpers =====

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
	task.delay(0.35, function() if lbl and lbl.Parent then lbl.Visible = false end end)
end

local function playError() errorSound:Stop(); errorSound.TimePosition = 0; errorSound:Play() end
local function playPurchase() purchaseSound:Stop(); purchaseSound.TimePosition = 0; purchaseSound:Play() end

local function getTemplateFolder(cat)
	if cat=="Ranged" or cat=="Melee" then return toolsRoot[cat]
	elseif cat=="Auras" then return aurasRoot end
end

-- read meta from Instance(ValueObject children) OR small {Key={Value=...}} tables
local function getMetaValue(tmpl, key)
	if typeof(tmpl) == "Instance" then
		local v = tmpl:FindFirstChild(key)
		return v and v.Value or nil
	elseif type(tmpl) == "table" then
		local node = tmpl[key]
		return node and node.Value or nil
	end
	return nil
end

local function ensureStroke(lbl)
	local st = lbl:FindFirstChild("UIStroke")
	if not st then
		st = Instance.new("UIStroke")
		st.Name = "UIStroke"
		st.Color = Color3.fromRGB(0,0,0)
		st.Thickness = 2
		st.LineJoinMode = Enum.LineJoinMode.Round
		st.Parent = lbl
	end
	return st
end

-- big text overlay inside PreviewImage area
local function setOverlayTextInPreview(button, text, color)
	local holder = button:FindFirstChild("PreviewImage")
	if not holder then
		-- fallback to NameLabel
		if button:FindFirstChild("NameLabel") then
			button.NameLabel.Text = text
			button.NameLabel.TextColor3 = color
			ensureStroke(button.NameLabel)
		end
		return
	end
	holder.ImageTransparency = 1
	local t = holder:FindFirstChild("OverlayText")
	if not t then
		t = Instance.new("TextLabel")
		t.Name = "OverlayText"
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1,1)
		t.Position = UDim2.fromScale(0,0)
		t.TextScaled = true
		t.Font = Enum.Font.GothamBold
		t.TextWrapped = true
		t.ZIndex = holder.ZIndex + 1
		t.Parent = holder
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(0,0,0)
		stroke.Thickness = 2
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		stroke.Parent = t
	end
	t.Text = text
	t.TextColor3 = color
end

-- Creates a tile button.
-- Auras: tile bg = rarity color; big name text in preview area (rarity color) + black outline.
-- Weapons/Crates: use icon if provided.
local function makeBtn(parent, name, tmpl, tpl, cat)
	local b = tpl:Clone()
	b.Name, b.Visible, b.Parent = name, true, parent

	local rarity = getMetaValue(tmpl, "Rarity") or "Basic"
	local iconId = getMetaValue(tmpl, "IconID") or ""
	local col    = rc[rarity] or rc.Basic

	if cat == "Auras" then
		b.BackgroundColor3 = col
		b.BorderSizePixel  = 2
		b.BorderColor3     = Color3.fromRGB(0,0,0)

		-- Label text color (and kill any gradients that override it)
		if b:FindFirstChild("NameLabel") then
			local lbl = b.NameLabel
			lbl.Text = name
			lbl.TextColor3 = col
			lbl.TextTransparency = 0
			lbl.RichText = false
			for _,d in ipairs(lbl:GetChildren()) do
				if d:IsA("UIGradient") then d:Destroy() end
			end
			ensureStroke(lbl)
		end

		-- Big name overlay in preview area too
		if b:FindFirstChild("PreviewImage") then
			b.PreviewImage.Image = ""
			setOverlayTextInPreview(b, name, col)
		end
	else
		-- weapons/crates
		b.BackgroundColor3 = col
		b.BorderSizePixel  = 1
		b.BorderColor3     = Color3.fromRGB(0,0,0)
		if b:FindFirstChild("PreviewImage") then
			b.PreviewImage.Image = (iconId ~= "" and ("rbxassetid://"..tostring(iconId))) or ""
		end
		if b:FindFirstChild("NameLabel") then
			b.NameLabel.Text = name
			b.NameLabel.TextColor3 = Color3.fromRGB(255,255,255)
			for _,d in ipairs(b.NameLabel:GetChildren()) do
				if d:IsA("UIGradient") then d:Destroy() end
			end
		end
	end

	return b
end

-- ===== SHOP lists (cost ↑) =====

local function buildShop(cat, list)
	clear(list)
	if not shopF:FindFirstChild(cat) then return end

	local items = {}
	for _,v in ipairs(shopF[cat]:GetChildren()) do table.insert(items, v) end
	table.sort(items, function(a,b)
		local ca = (a:FindFirstChild("Cost") and a.Cost.Value) or 0
		local cb = (b:FindFirstChild("Cost") and b.Cost.Value) or 0
		if ca == cb then return a.Name < b.Name end
		return ca < cb
	end)

	local tmplFolder = getTemplateFolder(cat)
	for idx,v in ipairs(items) do
		local tmpl = tmplFolder and tmplFolder:FindFirstChild(v.Name)
		local meta = tmpl or { Rarity={Value="Common"}, Description={Value=""}, IconID={Value=""} }

		-- aura shop exclusivity
		if cat=="Auras" and typeof(tmpl)=="Instance" then
			local sell = tmpl:FindFirstChild("ShopSellable")
			if sell and sell.Value == false then
				continue
			end
		end

		local cost = (v:FindFirstChild("Cost") and v.Cost.Value) or 0
		local btn  = makeBtn(list, v.Name, meta, shopTemplate, cat)
		btn.LayoutOrder = idx
		btn.MouseButton1Click:Connect(function()
			if spinning then return end
			sDet.Visible, sMsg.Visible = true, false
			if sDet:FindFirstChild("BigImage") then
				sDet.BigImage.Image = btn:FindFirstChild("PreviewImage") and btn.PreviewImage.Image or ""
			end
			sDet.ItemName.Text    = v.Name
			sDet.Description.Text = (typeof(tmpl)=="Instance" and tmpl:FindFirstChild("Description") and tmpl.Description.Value) or ""
			local AB = sDet:WaitForChild("ActionButton")
			local AL = AB.TextLabel
			if buyConn then buyConn:Disconnect() end
			AB.Active = true

			if inv:FindFirstChild(v.Name) then
				AL.Text = "Owned"; AB.Active = false
			else
				AL.Text = ((cat=="Auras") and "Buy Aura (" or "Buy (")..cost.."c)"
				buyConn = AB.MouseButton1Click:Connect(function()
					if spinning or inv:FindFirstChild(v.Name) then return end
					if pl.Coins.Value < cost then
						showMessage(sMsg,"Can't afford"); playError(); return
					end
					AB.Active = false
					buyR:FireServer(cat, v.Name)
				end)
			end
		end)
	end
end

local function buildCrates()
	clear(sCL)
	if not shopF:FindFirstChild("Crates") then return end

	local crates = {}
	for _,c in ipairs(shopF.Crates:GetChildren()) do
		table.insert(crates, c)
	end

	table.sort(crates, function(a,b)
		local ca = (a:FindFirstChild("Cost") and a.Cost.Value) or 0
		local cb = (b:FindFirstChild("Cost") and b.Cost.Value) or 0
		if ca == cb then return a.Name < b.Name end
		return ca < cb
	end)

	for idx,c in ipairs(crates) do
		local meta = {
			Rarity = { Value = "Basic" },
			IconID = { Value = (c:FindFirstChild("IconID") and c.IconID.Value) or "" }
		}
		local btn = makeBtn(sCL, c.Name, meta, shopTemplate, "Crates")
		btn.LayoutOrder = idx
		btn.MouseButton1Click:Connect(function()
			if spinning then return end
			local cost = (c:FindFirstChild("Cost") and c.Cost.Value) or 0
			sDet.Visible, sMsg.Visible = true, false
			if sDet:FindFirstChild("BigImage") then
				sDet.BigImage.Image = btn:FindFirstChild("PreviewImage") and btn.PreviewImage.Image or ""
			end
			sDet.ItemName.Text    = c.Name
			sDet.Description.Text = "Opens for "..cost.."c"
			local AB, AL = sDet.ActionButton, sDet.ActionButton.TextLabel
			if buyConn then buyConn:Disconnect() end
			AB.Active, AL.Text = true, "Open ("..cost.."c)"
			buyConn = AB.MouseButton1Click:Connect(function()
				if spinning then return end
				if pl.Coins.Value < cost then
					showMessage(sMsg, "Can't afford"); playError(); return
				end
				AB.Active = false
				openCrate:FireServer(c.Name)
			end)
		end)
	end
end

-- ===== INVENTORY (cost ↑) =====

local function buildInv(cat, list)
	clear(list)
	local tmplFolder = getTemplateFolder(cat)
	if not tmplFolder then return end

	local owned = {}
	for _,v in ipairs(inv:GetChildren()) do
		if v.Value and tmplFolder:FindFirstChild(v.Name) then
			local shopCat = shopF:FindFirstChild(cat)
			local shopItem = shopCat and shopCat:FindFirstChild(v.Name)
			local costVal  = shopItem and shopItem:FindFirstChild("Cost")
			local cost     = costVal and costVal.Value or 0
			table.insert(owned, {inst=v, cost=cost})
		end
	end
	table.sort(owned, function(a,b)
		if a.cost == b.cost then return a.inst.Name < b.inst.Name end
		return a.cost < b.cost
	end)

	for idx,entry in ipairs(owned) do
		local v    = entry.inst
		local tmpl = tmplFolder:FindFirstChild(v.Name) or { Rarity={Value="Common"} }
		local btn  = makeBtn(list, v.Name, tmpl, invTemplate, cat)
		btn.LayoutOrder = idx
		btn.MouseButton1Click:Connect(function()
			if spinning then return end
			iDet.Visible, iMsg.Visible = true, false
			if iDet:FindFirstChild("BigImage") then
				iDet.BigImage.Image = btn:FindFirstChild("PreviewImage") and btn.PreviewImage.Image or ""
			end
			iDet.ItemName.Text    = v.Name
			iDet.Description.Text = (typeof(tmpl)=="Instance" and tmpl:FindFirstChild("Description") and tmpl.Description.Value) or ""
			local AB = iDet:WaitForChild("ActionButton")
			local AL = AB.TextLabel
			if eqConn then eqConn:Disconnect() end
			AB.Active = true

			local isEq =
				(cat=="Ranged" and eqRng.Value==v.Name) or
				(cat=="Melee"  and eqMlv.Value==v.Name) or
				(cat=="Auras"  and eqAura.Value==v.Name)

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

-- ===== Spinner =====

local function buildSpinner(drops, won)
	spinning = true
	sFrame.Visible = false
	iFrame.Visible = false

	clear(reel)
	reel.CanvasPosition = Vector2.new(0,0)

	-- Build sequence (repeat) and put winner in middle
	local seq = {}
	for i=1,5 do for _,d in ipairs(drops) do table.insert(seq, d) end end
	local mid = math.ceil(#seq/2)
	local wonData
	for _,d in ipairs(drops) do if d.Name==won then wonData=d break end end
	if wonData then table.insert(seq, mid, wonData) end

	for idx,d in ipairs(seq) do
		local b = spinTpl:Clone()
		b.Visible     = true
		b.Parent      = reel
		b.LayoutOrder = idx

		-- tile color by rarity
		b.BackgroundColor3 = rc[d.Rarity] or rc.Basic
		if b:FindFirstChild("PreviewImage") then
			-- Show icon for non-auras (if provided), otherwise overlay text
			if d.Category ~= "Auras" and d.IconID and d.IconID ~= "" then
				b.PreviewImage.Image = d.IconID -- server sends with "rbxassetid://" prefix
				-- optional: also show name text over icon if you like; keeping icon only
			else
				b.PreviewImage.Image = ""
				-- overlay name text
				local holder = b.PreviewImage
				holder.ImageTransparency = 1
				local t = holder:FindFirstChild("OverlayText") or Instance.new("TextLabel")
				t.Name = "OverlayText"
				t.BackgroundTransparency = 1
				t.Size = UDim2.fromScale(1,1)
				t.Position = UDim2.fromScale(0,0)
				t.TextScaled = true
				t.Font = Enum.Font.GothamBold
				t.TextWrapped = true
				t.ZIndex = holder.ZIndex + 1
				t.Text = d.Name
				t.TextColor3 = rc[d.Rarity] or rc.Basic
				t.Parent = holder
				-- stroke
				local s = t:FindFirstChild("UIStroke") or Instance.new("UIStroke")
				s.Color = Color3.fromRGB(0,0,0)
				s.Thickness = 2
				s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
				s.Parent = t
			end
		end

		-- If your template also has NameLabel, set it too (redundant but safe)
		if b:FindFirstChild("NameLabel") then
			b.NameLabel.Text = d.Name
			b.NameLabel.TextColor3 = Color3.fromRGB(0,0,0) -- keep subtle; main text sits in preview area
		end
	end

	reelLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Wait()
	reel.CanvasSize = UDim2.new(0, reelLayout.AbsoluteContentSize.X, 0, 0)

	local slotW = spinTpl.AbsoluteSize.X
	local fw    = spinnerF.AbsoluteSize.X
	local target = slotW*(mid-1) - (fw/2 - slotW/2)
	local tween = TweenService:Create(
		reel, TweenInfo.new(3, Enum.EasingStyle.Cubic),
		{ CanvasPosition = Vector2.new(target,0) }
	)

	purchaseSound:Play()
	spinnerF.Visible = true
	tween:Play(); tween.Completed:Wait()

	receivedLbl.Text      = "Received "..won
	receivedLbl.TextColor3= rc[wonData and wonData.Rarity or "Basic"] or rc.Basic
	receivedLbl.Visible   = true

	task.delay(1, function()
		spinnerF.Visible     = false
		receivedLbl.Visible  = false
		clear(reel)
		spinning = false
		buildInv("Ranged", iRL)
		buildInv("Melee",  iML)
		buildInv("Auras",  iAL)
	end)
end

-- ===== Remote listeners =====

eLobby.OnClientEvent:Connect(function()
	ui.OpenShopButton.Visible, ui.OpenInvButton.Visible = true, true
end)
eBeginRound.OnClientEvent:Connect(function()
	ui.OpenShopButton.Visible, ui.OpenInvButton.Visible = false, false
	sFrame.Visible, iFrame.Visible  = false, false
end)

crateRes.OnClientEvent:Connect(function(ok, _, won, drops)
	if ok then buildSpinner(drops, won) end
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
		buildShop("Auras",  sAL)
		buildInv("Auras",   iAL)
	end
end)

equipRes.OnClientEvent:Connect(function(ok, cat, itemName)
	if ok then
		if iDet.Visible and iDet.ItemName.Text==itemName then
			local AB, AL = iDet:WaitForChild("ActionButton"), iDet.ActionButton.TextLabel
			AL.Text, AB.Active = "Equipped", false
		end
		buildInv("Ranged", iRL)
		buildInv("Melee",  iML)
		buildInv("Auras",  iAL)
	end
end)

-- ===== UI wiring =====
sFrame.Visible = false
iFrame.Visible = false

local function showShop(tab)
	if spinning then return end
	sFrame.Visible, iFrame.Visible = true, false
	buildShop("Ranged", sRL)
	buildShop("Melee",  sML)
	buildShop("Auras",  sAL)
	if tab == "Ranged" then
		sRL.Visible, sML.Visible, sAL.Visible, sCL.Visible = true,false,false,false
	elseif tab == "Melee" then
		sRL.Visible, sML.Visible, sAL.Visible, sCL.Visible = false,true,false,false
	elseif tab == "Auras" then
		sRL.Visible, sML.Visible, sAL.Visible, sCL.Visible = false,false,true,false
	end
end

ui.OpenShopButton.MouseButton1Click:Connect(function() showShop("Ranged") end)
sClose.MouseButton1Click:Connect(function() sFrame.Visible = false end)

ui.OpenInvButton.MouseButton1Click:Connect(function()
	if spinning then return end
	iFrame.Visible, sFrame.Visible = true, false
	buildInv("Ranged", iRL)
	buildInv("Melee",  iML)
	buildInv("Auras",  iAL)
	iRL.Visible, iML.Visible, iAL.Visible = true,false,false
end)
iClose.MouseButton1Click:Connect(function() iFrame.Visible = false end)

sRT.MouseButton1Click:Connect(function() buildShop("Ranged", sRL); sRL.Visible, sML.Visible, sAL.Visible, sCL.Visible = true,false,false,false end)
sMT.MouseButton1Click:Connect(function() buildShop("Melee",  sML); sRL.Visible, sML.Visible, sAL.Visible, sCL.Visible = false,true,false,false end)
sAT.MouseButton1Click:Connect(function() buildShop("Auras",  sAL); sRL.Visible, sML.Visible, sAL.Visible, sCL.Visible = false,false,true,false end)
sCT.MouseButton1Click:Connect(function() if spinning then return end; buildCrates(); sRL.Visible, sML.Visible, sAL.Visible, sCL.Visible = false,false,false,true end)

iRT.MouseButton1Click:Connect(function() buildInv("Ranged", iRL); iRL.Visible, iML.Visible, iAL.Visible = true,false,false end)
iMT.MouseButton1Click:Connect(function() buildInv("Melee",  iML); iRL.Visible, iML.Visible, iAL.Visible = false,true,false end)
iAT.MouseButton1Click:Connect(function() buildInv("Auras",  iAL); iRL.Visible, iML.Visible, iAL.Visible = false,false,true end)

-- Initial builds
buildShop("Ranged", sRL)
buildShop("Melee",  sML)
buildShop("Auras",  sAL)
