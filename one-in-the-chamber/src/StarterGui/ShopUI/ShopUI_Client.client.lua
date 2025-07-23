local RS       = game:GetService("ReplicatedStorage")
local Players  = game:GetService("Players")
local pl       = Players.LocalPlayer

local rem      = RS.GameRemotes
local buyR     = rem.PurchaseItem
local eqR      = rem.EquipItem
local lobbyEvt = rem.StartLobby
local roundEvt = rem.BeginRound

local shopTags = RS.Shop
local tmplRoot = RS.ToolTemplates

local ui       = script.Parent
local btnShop  = ui.OpenShopButton
local btnInv   = ui.OpenInvButton

local sFrame   = ui.ShopFrame
local sClose   = sFrame.CloseButton
local sRT      = sFrame.RangedTab
local sMT      = sFrame.MeleeTab
local sRL      = sFrame.RangedList
local sML      = sFrame.MeleeList
local sDet     = sFrame.ShopDetailsFrame

local iFrame   = ui.InvFrame
local iClose   = iFrame.CloseInvButton
local iRT      = iFrame.InvRangedTab
local iMT      = iFrame.InvMeleeTab
local iRL      = iFrame.InvRangedList
local iML      = iFrame.InvMeleeList
local iDet     = iFrame.InvDetailsFrame

local itemT    = sFrame.ItemTemplate
itemT.Visible  = false

local inv      = pl:WaitForChild("Inventory")
local eqRngVal = pl:WaitForChild("EquippedRanged")
local eqMelVal = pl:WaitForChild("EquippedMelee")

local rc = {
	Basic=Color3.fromRGB(200,200,200),
	Common=Color3.fromRGB(170,170,170),
	Uncommon=Color3.fromRGB(100,255,100),
	Rare=Color3.fromRGB(100,150,255),
	Epic=Color3.fromRGB(200,100,255),
	Legendary=Color3.fromRGB(255,200,100)
}


local function clear(frame)
	for _,c in ipairs(frame:GetChildren()) do
		if c:IsA("TextButton") and c~=itemT then c:Destroy() end
	end
end

local function makeButton(parent,name,tmpl)
	local b=itemT:Clone()
	b.Visible=true b.Parent=parent b.Name=name
	b.BackgroundColor3=rc[tmpl:FindFirstChild("Rarity")and tmpl.Rarity.Value or"Basic"]
	b.PreviewImage.Image=tmpl:FindFirstChild("IconID")and"rbxassetid://"..tmpl.IconID.Value or""
	b.NameLabel.Text=name
	return b
end


local function buildShop(cat,list)
	clear(list)
	for _,v in ipairs(shopTags[cat]:GetChildren())do
		local name=v.Name
		local tmpl=tmplRoot[cat]:FindFirstChild(name) if not tmpl then continue end
		local btn=makeButton(list,name,tmpl)
		btn.MouseButton1Click:Connect(function()
			sDet.Visible=true
			sDet.BigImage.Image=btn.PreviewImage.Image
			sDet.ItemName.Text=name
			sDet.Description.Text=tmpl:FindFirstChild("Description")and tmpl.Description.Value or""
			local aBtn,aLbl=sDet.ActionButton,sDet.ActionButton.TextLabel
			if _G.sConn then _G.sConn:Disconnect() end
			if inv:FindFirstChild(name) then
				aLbl.Text="Owned" aBtn.Active=false
				_G.sConn=nil
			else
				aLbl.Text="Buy ("..v.Cost.Value.."c)" aBtn.Active=true
				_G.sConn=aBtn.MouseButton1Click:Connect(function()
					aBtn.Active=false
					buyR:FireServer(cat,name)
				end)
			end
		end)
	end
end


local function buildInv(cat,list)
	clear(list)
	for _,own in ipairs(inv:GetChildren())do
		if not own.Value then continue end
		local name=own.Name
		local tmpl=tmplRoot[cat]:FindFirstChild(name) if not tmpl then continue end
		local btn=makeButton(list,name,tmpl)
		btn.MouseButton1Click:Connect(function()
			iDet.Visible=true
			iDet.BigImage.Image=btn.PreviewImage.Image
			iDet.ItemName.Text=name
			iDet.Description.Text=tmpl:FindFirstChild("Description")and tmpl.Description.Value or""
			local aBtn,aLbl=iDet.ActionButton,iDet.ActionButton.TextLabel
			if _G.iConn then _G.iConn:Disconnect() end
			if (cat=="Ranged"and eqRngVal.Value==name)or(cat=="Melee"and eqMelVal.Value==name)then
				aLbl.Text="Equipped" aBtn.Active=false
				_G.iConn=nil
			else
				aLbl.Text="Equip" aBtn.Active=true
				_G.iConn=aBtn.MouseButton1Click:Connect(function()
					aBtn.Active=false
					eqR:FireServer(cat,name)
				end)
			end
		end)
	end
end


btnShop.MouseButton1Click:Connect(function()
	iFrame.Visible=false
	buildShop("Ranged",sRL) buildShop("Melee",sML)
	sFrame.Visible=true
end)
sClose.MouseButton1Click:Connect(function() sFrame.Visible=false end)
sRT.MouseButton1Click:Connect(function() sRL.Visible=true sML.Visible=false end)
sMT.MouseButton1Click:Connect(function() sRL.Visible=false sML.Visible=true end)

btnInv.MouseButton1Click:Connect(function()
	sFrame.Visible=false
	buildInv("Ranged",iRL) buildInv("Melee",iML)
	iFrame.Visible=true
end)
iClose.MouseButton1Click:Connect(function() iFrame.Visible=false end)
iRT.MouseButton1Click:Connect(function() iRL.Visible=true iML.Visible=false end)
iMT.MouseButton1Click:Connect(function() iRL.Visible=false iML.Visible=true end)


lobbyEvt.OnClientEvent:Connect(function()
	btnShop.Visible=true btnInv.Visible=true
end)
roundEvt.OnClientEvent:Connect(function()
	sFrame.Visible=false iFrame.Visible=false
	btnShop.Visible=false btnInv.Visible=false
end)


buyR.OnClientEvent:Connect(function(ok,name)
	if not ok then return end
	if not inv:FindFirstChild(name) then
		local v=Instance.new("BoolValue",inv) v.Name=name v.Value=true
	end
	buildShop("Ranged",sRL) buildShop("Melee",sML)
	if sDet.Visible and sDet.ItemName.Text==name then
		local a=sDet.ActionButton a.TextLabel.Text="Owned" a.Active=false
		if _G.sConn then _G.sConn:Disconnect() _G.sConn=nil end
	end
end)

eqR.OnClientEvent:Connect(function(ok,cat,name)
	if not ok then return end
	if cat=="Ranged"then eqRngVal.Value=name else eqMelVal.Value=name end
	buildInv("Ranged",iRL) buildInv("Melee",iML)
	if iDet.Visible and iDet.ItemName.Text==name then
		local a=iDet.ActionButton a.TextLabel.Text="Equipped" a.Active=false
		if _G.iConn then _G.iConn:Disconnect() _G.iConn=nil end
	end
end)


buildShop("Ranged",sRL) buildShop("Melee",sML)
