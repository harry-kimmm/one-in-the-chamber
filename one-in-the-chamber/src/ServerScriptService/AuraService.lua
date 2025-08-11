-- ServerScriptService/AuraService
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local AURAS_FOLDER      = RS:WaitForChild("Auras")
local DEFAULT_AURA_NAME = "DefaultAura"

local AuraService = {}

local enabled = false
local currentLeader = nil

local killsConns   = {}
local charConns    = {}
local equipConns   = {} -- { [player] = { svConn=?, attrConn=? } }
local playerAddedConn, playerRemovingConn

local R6_TO_R15 = {
	["Torso"]     = "UpperTorso",
	["Left Arm"]  = "LeftUpperArm",
	["Right Arm"] = "RightUpperArm",
	["Left Leg"]  = "LeftUpperLeg",
	["Right Leg"] = "RightUpperLeg",
}

local FX_CLASSES = {
	ParticleEmitter = true,
	Beam = true,
	Trail = true,
	PointLight = true,
	SpotLight = true,
	SurfaceLight = true,
	BillboardGui = true,
}

local function getKills(pl)
	local ls = pl:FindFirstChild("leaderstats")
	local k  = ls and ls:FindFirstChild("Kills")
	return k and k.Value or 0
end

local function getEquippedAuraName(pl)
	if not pl then return DEFAULT_AURA_NAME end
	local sv = pl:FindFirstChild("EquippedAura")
	if sv and sv:IsA("StringValue") and sv.Value ~= "" then
		return sv.Value
	end
	local attr = pl:GetAttribute("EquippedAura")
	if typeof(attr) == "string" and attr ~= "" then
		return attr
	end
	return DEFAULT_AURA_NAME
end

local function tag(inst, pl, auraName)
	inst:SetAttribute("__AuraTag", true)
	inst:SetAttribute("__AuraOwnerUserId", pl.UserId)
	inst:SetAttribute("__AuraName", auraName)
end

local function clearAura(pl)
	local char = pl and pl.Character
	if not char then return end
	for _, d in ipairs(char:GetDescendants()) do
		if d:GetAttribute("__AuraTag") then
			d:Destroy()
		end
	end
	for _, folder in ipairs(char:GetChildren()) do
		if folder:IsA("Folder") and folder.Name:match("^Aura_") then
			folder:Destroy()
		end
	end
end

local function findDestPart(char, srcPartName)
	if not char then return nil end
	local exact = char:FindFirstChild(srcPartName, true)
	if exact and exact:IsA("BasePart") then return exact end
	local mapped = R6_TO_R15[srcPartName]
	if mapped then
		local m = char:FindFirstChild(mapped, true)
		if m and m:IsA("BasePart") then return m end
	end
	for _, p in ipairs({"Head","HumanoidRootPart","UpperTorso","LowerTorso","Torso"}) do
		if srcPartName == p then
			local cand = char:FindFirstChild(p, true)
			if cand and cand:IsA("BasePart") then return cand end
		end
	end
	return nil
end

local function nearestBasePart(obj)
	local cur = obj
	while cur and not cur:IsA("BasePart") do
		cur = cur.Parent
	end
	return cur
end

local function applyAura(pl)
	local char = pl and pl.Character
	if not char then return end

	local auraName = getEquippedAuraName(pl)
	local tmpl = AURAS_FOLDER:FindFirstChild(auraName)
	if not tmpl then
		warn(("AuraService: aura '%s' not found; falling back to '%s'"):format(auraName, DEFAULT_AURA_NAME))
		auraName = DEFAULT_AURA_NAME
		tmpl = AURAS_FOLDER:FindFirstChild(auraName)
		if not tmpl then return end
	end

	local auraFolder = Instance.new("Folder")
	auraFolder.Name = "Aura_"..auraName
	auraFolder.Parent = char
	tag(auraFolder, pl, auraName)

	local attMap = {}
	for _, obj in ipairs(tmpl:GetDescendants()) do
		if obj:IsA("Attachment") then
			local srcPart = nearestBasePart(obj)
			if srcPart and srcPart:IsA("BasePart") then
				local dstPart = findDestPart(char, srcPart.Name)
				if dstPart then
					local ac = obj:Clone()
					ac.Parent = dstPart
					tag(ac, pl, auraName)
					attMap[obj] = ac
				else
					warn(("AuraService: missing dest part '%s' for %s"):format(srcPart.Name, pl.Name))
				end
			end
		end
	end

	local function resolveFxParent(src)
		if src.Parent and src.Parent:IsA("Attachment") then
			local attClone = attMap[src.Parent]
			if attClone then return attClone end
		end
		local srcPart = nearestBasePart(src)
		if not (srcPart and srcPart:IsA("BasePart")) then
			return auraFolder
		end
		local dstPart = findDestPart(char, srcPart.Name)
		return dstPart or auraFolder
	end

	for _, obj in ipairs(tmpl:GetDescendants()) do
		if FX_CLASSES[obj.ClassName] then
			local parentDst = resolveFxParent(obj)
			if not parentDst then continue end

			if obj:IsA("ParticleEmitter") then
				local dstAttachment
				if parentDst:IsA("Attachment") then
					dstAttachment = parentDst
				elseif parentDst:IsA("BasePart") then
					dstAttachment = Instance.new("Attachment")
					dstAttachment.Name = "AuraAttach_"..auraName
					dstAttachment.Parent = parentDst
					tag(dstAttachment, pl, auraName)
				else
					local hrp = char:FindFirstChild("HumanoidRootPart")
					if hrp then
						dstAttachment = Instance.new("Attachment")
						dstAttachment.Name = "AuraAttach_"..auraName
						dstAttachment.Parent = hrp
						tag(dstAttachment, pl, auraName)
					end
				end
				if dstAttachment then
					local pe = obj:Clone()
					pe.Parent = dstAttachment
					tag(pe, pl, auraName)
				end

			elseif obj:IsA("Beam") then
				local beam = obj:Clone()
				beam.Parent = auraFolder
				beam.Attachment0 = (obj.Attachment0 and attMap[obj.Attachment0]) or nil
				beam.Attachment1 = (obj.Attachment1 and attMap[obj.Attachment1]) or nil
				tag(beam, pl, auraName)

			elseif obj:IsA("Trail") then
				local trail = obj:Clone()
				trail.Parent = auraFolder
				trail.Attachment0 = (obj.Attachment0 and attMap[obj.Attachment0]) or nil
				trail.Attachment1 = (obj.Attachment1 and attMap[obj.Attachment1]) or nil
				tag(trail, pl, auraName)

			else
				local fx = obj:Clone()
				fx.Parent = parentDst
				tag(fx, pl, auraName)
			end
		end
	end
end

local function computeLeader()
	if not enabled then return nil end
	local maxKills = -math.huge
	local leaders = {}
	for _, pl in ipairs(Players:GetPlayers()) do
		local k = getKills(pl)
		if k > maxKills then
			maxKills = k
			leaders = { pl }
		elseif k == maxKills then
			table.insert(leaders, pl)
		end
	end
	if #leaders == 1 and maxKills > -math.huge then
		return leaders[1]
	end
	return nil
end

local function refreshLeader()
	local newLeader = computeLeader()
	if newLeader == currentLeader then return end
	if currentLeader then clearAura(currentLeader) end
	currentLeader = newLeader
	if currentLeader and enabled then
		applyAura(currentLeader)
	end
end

local function onEquippedAuraChanged(pl)
	if enabled and pl == currentLeader then
		clearAura(pl)
		applyAura(pl)
	end
end

local function hookPlayer(pl)
	local ls = pl:FindFirstChild("leaderstats")
	local killsVal = ls and ls:FindFirstChild("Kills")
	if killsVal and not killsConns[pl] then
		killsConns[pl] = killsVal:GetPropertyChangedSignal("Value"):Connect(function()
			refreshLeader()
		end)
	end
	if not charConns[pl] then
		charConns[pl] = pl.CharacterAdded:Connect(function()
			task.wait(0.15)
			if enabled and pl == currentLeader then
				applyAura(pl)
			end
		end)
	end
	-- watch equipped aura (StringValue + Attribute)
	if not equipConns[pl] then equipConns[pl] = {} end
	local sv = pl:FindFirstChild("EquippedAura")
	if sv and not equipConns[pl].svConn then
		equipConns[pl].svConn = sv.Changed:Connect(function()
			onEquippedAuraChanged(pl)
		end)
	end
	if not equipConns[pl].attrConn then
		equipConns[pl].attrConn = pl:GetAttributeChangedSignal("EquippedAura"):Connect(function()
			onEquippedAuraChanged(pl)
		end)
	end
end

function AuraService.BeginRound()
	enabled = true
	for _, pl in ipairs(Players:GetPlayers()) do
		hookPlayer(pl)
	end
	if not playerAddedConn then
		playerAddedConn = Players.PlayerAdded:Connect(function(pl)
			task.wait(0.1)
			hookPlayer(pl)
			refreshLeader()
		end)
	end
	if not playerRemovingConn then
		playerRemovingConn = Players.PlayerRemoving:Connect(function(pl)
			if killsConns[pl] then killsConns[pl]:Disconnect(); killsConns[pl] = nil end
			if charConns[pl]  then charConns[pl]:Disconnect();  charConns[pl]  = nil end
			if equipConns[pl] then
				if equipConns[pl].svConn then equipConns[pl].svConn:Disconnect() end
				if equipConns[pl].attrConn then equipConns[pl].attrConn:Disconnect() end
				equipConns[pl] = nil
			end
			if currentLeader == pl then currentLeader = nil; task.defer(refreshLeader) end
		end)
	end
	refreshLeader()
end

function AuraService.EndRound()
	enabled = false
	if currentLeader then clearAura(currentLeader); currentLeader = nil end
	for pl, conn in pairs(killsConns) do conn:Disconnect() end
	for pl, conn in pairs(charConns) do conn:Disconnect() end
	for pl, t in pairs(equipConns) do
		if t.svConn then t.svConn:Disconnect() end
		if t.attrConn then t.attrConn:Disconnect() end
	end
	table.clear(killsConns)
	table.clear(charConns)
	table.clear(equipConns)
end

return AuraService
