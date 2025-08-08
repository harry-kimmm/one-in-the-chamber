-- ServerScriptService/AuraService.lua
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local AURAS_FOLDER       = RS:WaitForChild("Auras")
local DEFAULT_AURA_NAME  = "DefaultAura"

local AuraService = {}

local enabled = false
local currentLeader = nil

local killsConns   = {}
local charConns    = {}
local auraConns    = {} -- NEW: reapply if leader changes equipped aura
local playerAddedConn, playerRemovingConn

local function getKills(pl)
	local ls = pl:FindFirstChild("leaderstats")
	local k  = ls and ls:FindFirstChild("Kills")
	return k and k.Value or 0
end

local function tag(inst, pl)
	inst:SetAttribute("__AuraTag", true)
	inst:SetAttribute("__AuraOwnerUserId", pl.UserId)
end

local function clearAura(pl)
	local char = pl and pl.Character
	if not char then return end
	for _, d in ipairs(char:GetDescendants()) do
		if d:GetAttribute("__AuraTag") then
			d:Destroy()
		end
	end
end

local function findPartByName(char, partName)
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == partName then
			return d
		end
	end
end

local function applyAura(pl)
	local char = pl.Character
	if not char then return end

	local chosen = (pl:FindFirstChild("EquippedAura") and pl.EquippedAura.Value ~= "" and pl.EquippedAura.Value)
		or DEFAULT_AURA_NAME
	local tmpl = AURAS_FOLDER:FindFirstChild(chosen) or AURAS_FOLDER:FindFirstChild(DEFAULT_AURA_NAME)
	if not tmpl then return end

	-- Copy attachments & emitters, tagging for cleanup
	for _, obj in ipairs(tmpl:GetDescendants()) do
		if obj:IsA("Attachment") then
			local srcPart = obj.Parent
			if srcPart and srcPart:IsA("BasePart") then
				local dstPart = findPartByName(char, srcPart.Name)
				if dstPart then
					local attClone = obj:Clone()
					attClone.Parent = dstPart
					tag(attClone, pl)
					for _, sub in ipairs(attClone:GetDescendants()) do tag(sub, pl) end
				end
			end
		elseif obj:IsA("ParticleEmitter") and obj.Parent and obj.Parent:IsA("BasePart") then
			local dstPart = findPartByName(char, obj.Parent.Name)
			if dstPart then
				local holder = Instance.new("Attachment")
				holder.Name = "AuraAttach_" .. chosen
				holder.Parent = dstPart
				tag(holder, pl)
				local em = obj:Clone()
				em.Parent = holder
				tag(em, pl)
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

local function hookPlayer(pl)
	-- Kills change
	local ls = pl:FindFirstChild("leaderstats")
	local killsVal = ls and ls:FindFirstChild("Kills")
	if killsVal and not killsConns[pl] then
		killsConns[pl] = killsVal:GetPropertyChangedSignal("Value"):Connect(refreshLeader)
	end
	-- Reapply after respawn if still leader
	if not charConns[pl] then
		charConns[pl] = pl.CharacterAdded:Connect(function()
			task.wait(0.1)
			if enabled and pl == currentLeader then
				applyAura(pl)
			end
		end)
	end
	-- If leader changes their equipped aura mid-round, reapply
	if pl:FindFirstChild("EquippedAura") and not auraConns[pl] then
		auraConns[pl] = pl.EquippedAura:GetPropertyChangedSignal("Value"):Connect(function()
			if enabled and pl == currentLeader then
				clearAura(pl)
				applyAura(pl)
			end
		end)
	end
end

function AuraService.BeginRound()
	enabled = true
	for _, pl in ipairs(Players:GetPlayers()) do hookPlayer(pl) end
	if not playerAddedConn then
		playerAddedConn = Players.PlayerAdded:Connect(function(pl)
			task.wait(0.1); hookPlayer(pl); refreshLeader()
		end)
	end
	if not playerRemovingConn then
		playerRemovingConn = Players.PlayerRemoving:Connect(function(pl)
			if killsConns[pl] then killsConns[pl]:Disconnect(); killsConns[pl] = nil end
			if charConns[pl]  then charConns[pl]:Disconnect();  charConns[pl]  = nil end
			if auraConns[pl]  then auraConns[pl]:Disconnect();  auraConns[pl]  = nil end
			if currentLeader == pl then currentLeader = nil; task.defer(refreshLeader) end
		end)
	end
	refreshLeader()
end

function AuraService.EndRound()
	enabled = false
	if currentLeader then clearAura(currentLeader); currentLeader = nil end
	for pl,conn in pairs(killsConns) do conn:Disconnect() end; killsConns = {}
	for pl,conn in pairs(charConns)  do conn:Disconnect() end; charConns  = {}
	for pl,conn in pairs(auraConns)  do conn:Disconnect() end; auraConns  = {}
end

return AuraService
