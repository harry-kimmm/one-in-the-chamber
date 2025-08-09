print("[GameManager] loaded")

local Players              = game:GetService("Players")
local RS                   = game:GetService("ReplicatedStorage")
local DataStoreService     = game:GetService("DataStoreService")
local ServerScriptService  = game:GetService("ServerScriptService")

local KillStreaks  = require(ServerScriptService:WaitForChild("KillStreaks"))
local AuraService  = require(ServerScriptService:WaitForChild("AuraService"))

local remotes         = RS:WaitForChild("GameRemotes")
local evLobby         = remotes:WaitForChild("StartLobby")
local evRound         = remotes:WaitForChild("StartRound")
local evEnd           = remotes:WaitForChild("EndRound")
local evBeginRound    = remotes:WaitForChild("BeginRound")
local evProfileToggle = remotes:WaitForChild("ProfileToggle")

local firstPlaceEvent = remotes:FindFirstChild("FirstPlaceUpdate")
if not firstPlaceEvent then
	firstPlaceEvent = Instance.new("RemoteEvent")
	firstPlaceEvent.Name = "FirstPlaceUpdate"
	firstPlaceEvent.Parent = remotes
end

local toolTemplates    = RS:WaitForChild("ToolTemplates")
local HUB_SPAWNS       = workspace:WaitForChild("Hub"):WaitForChild("SpawnPoints")
local MAPS_FOLDER      = workspace:WaitForChild("Maps")

local MIN_PLAYERS = 1
local LOBBY_TIME  = 10
local ROUND_TIME  = 10
local KILL_LIMIT  = 10

local currentPhase     = "None"
local currentMapSpawns = HUB_SPAWNS
local lastLeader       = nil

local function dayKey()
	local t = os.date("!*t")
	return string.format("%04d%02d%02d", t.year, t.month, t.day)
end
local function weekKey()
	local t = os.date("!*t")
	local w = math.floor((t.yday - 1) / 7) + 1
	return string.format("%04dW%02d", t.year, w)
end
local function odsName(statType, period)
	if period == "Lifetime" then
		return "LB_" .. statType .. "_Lifetime"
	elseif period == "Weekly" then
		return "LB_" .. statType .. "_Weekly_" .. weekKey()
	else
		return "LB_" .. statType .. "_Daily_" .. dayKey()
	end
end

local counters = DataStoreService:GetDataStore("LB_Counters")

local function incrPeriod(statType, delta, userId)
	if delta == 0 then return end
	local dk = dayKey()
	local wk = weekKey()
	local dayKeyName   = statType .. "_Daily_"  .. dk .. "_" .. tostring(userId)
	local weekKeyName  = statType .. "_Weekly_" .. wk .. "_" .. tostring(userId)
	local newDay, newWeek

	local ok1, val1 = pcall(function() return counters:GetAsync(dayKeyName) end)
	local baseDay = (ok1 and val1) or 0
	newDay = baseDay + delta
	pcall(function() counters:SetAsync(dayKeyName, newDay) end)
	local dayODS = DataStoreService:GetOrderedDataStore(odsName(statType, "Daily"))
	pcall(function() dayODS:SetAsync(tostring(userId), newDay) end)

	local ok2, val2 = pcall(function() return counters:GetAsync(weekKeyName) end)
	local baseWeek = (ok2 and val2) or 0
	newWeek = baseWeek + delta
	pcall(function() counters:SetAsync(weekKeyName, newWeek) end)
	local weekODS = DataStoreService:GetOrderedDataStore(odsName(statType, "Weekly"))
	pcall(function() weekODS:SetAsync(tostring(userId), newWeek) end)
end

local function setLifetime(statType, absoluteValue, userId)
	local name = odsName(statType, "Lifetime")
	local ods = DataStoreService:GetOrderedDataStore(name)
	pcall(function() ods:SetAsync(tostring(userId), absoluteValue) end)
end

local function teleportTo(pl, spawns)
	local char = pl.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if root then
		local pts = spawns:GetChildren()
		if #pts > 0 then
			local choice = pts[math.random(1, #pts)]
			root.CFrame = choice.CFrame + Vector3.new(0, 3, 0)
		end
	end
end

local function giveLoadout(pl)
	if pl.Backpack then
		for _, t in ipairs(pl.Backpack:GetChildren()) do
			if t:IsA("Tool") then t:Destroy() end
		end
	end
	for _, key in ipairs({"EquippedRanged","EquippedMelee"}) do
		local v = pl:FindFirstChild(key)
		if v and v.Value ~= "" then
			local tmpl = toolTemplates:FindFirstChild(v.Value, true)
			if tmpl then tmpl:Clone().Parent = pl.Backpack end
		end
	end
end

local function onCharacterAdded(char)
	local pl  = Players:GetPlayerFromCharacter(char)
	if not pl then return end
	local hum = char:WaitForChild("Humanoid")
	hum.MaxHealth = 100
	hum.Health    = 100
	local ammo = pl:FindFirstChild("Ammo")
	if ammo then ammo.Value = (currentPhase=="Round") and 1001 or 0 end
	if currentPhase=="Lobby" then
		teleportTo(pl, HUB_SPAWNS)
	elseif currentPhase=="Round" then
		teleportTo(pl, currentMapSpawns)
		giveLoadout(pl)
	end
end

Players.PlayerAdded:Connect(function(pl)
	pl.CharacterAdded:Connect(onCharacterAdded)
end)
for _, pl in ipairs(Players:GetPlayers()) do
	pl.CharacterAdded:Connect(onCharacterAdded)
	if pl.Character then onCharacterAdded(pl.Character) end
end

local function getKills(pl)
	local ls = pl:FindFirstChild("leaderstats")
	local k  = ls and ls:FindFirstChild("Kills")
	return k and k.Value or 0
end

local function computeUniqueLeader()
	local maxKills = -math.huge
	local leaders = {}
	for _, pl in ipairs(Players:GetPlayers()) do
		local k = getKills(pl)
		if k > maxKills then
			maxKills = k
			leaders = {pl}
		elseif k == maxKills then
			table.insert(leaders, pl)
		end
	end
	if #leaders == 1 and maxKills > -math.huge then
		return leaders[1]
	end
	return nil
end

local function broadcastLeader(newLeader)
	if newLeader == lastLeader then return end
	lastLeader = newLeader
	for _, pl in ipairs(Players:GetPlayers()) do
		local isLeader = (newLeader ~= nil) and (pl == newLeader)
		firstPlaceEvent:FireClient(pl, isLeader, newLeader and newLeader.Name or "", newLeader and getKills(newLeader) or 0)
	end
end

local function startLobby()
	currentPhase     = "Lobby"
	currentMapSpawns = HUB_SPAWNS
	lastLeader       = nil
	broadcastLeader(nil)
	evProfileToggle:FireAllClients(true)
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl.Backpack then
			for _, t in ipairs(pl.Backpack:GetChildren()) do
				if t:IsA("Tool") then t:Destroy() end
			end
		end
		if pl.Character then
			for _, t in ipairs(pl.Character:GetChildren()) do
				if t:IsA("Tool") then t:Destroy() end
			end
		end
		teleportTo(pl, HUB_SPAWNS)
		local ammo = pl:FindFirstChild("Ammo")
		if ammo then ammo.Value = 0 end
	end
	for t = LOBBY_TIME, 1, -1 do
		evLobby:FireAllClients(t)
		task.wait(1)
	end
end

local function startRound()
	currentPhase = "Round"
	evProfileToggle:FireAllClients(false)
	for _, pl in ipairs(Players:GetPlayers()) do
		local ls = pl:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild("Kills") then
			ls.Kills.Value = 0
		end
	end
	local maps  = MAPS_FOLDER:GetChildren()
	local chosen = maps[math.random(1, #maps)]
	currentMapSpawns = chosen:WaitForChild("SpawnPoints")
	evBeginRound:FireAllClients(chosen.Name)
	for _, pl in ipairs(Players:GetPlayers()) do
		local ammo = pl:FindFirstChild("Ammo")
		if ammo then ammo.Value = 1001 end
		if pl.Character then
			local hum = pl.Character:FindFirstChild("Humanoid")
			if hum then hum.Health = 100 end
		end
		giveLoadout(pl)
		if pl.Character then teleportTo(pl, currentMapSpawns) end
	end
	AuraService.BeginRound()
	lastLeader = nil
	broadcastLeader(computeUniqueLeader())
	local winner
	for t = ROUND_TIME, 1, -1 do
		evRound:FireAllClients(t)
		broadcastLeader(computeUniqueLeader())
		for _, pl in ipairs(Players:GetPlayers()) do
			local ks = pl:FindFirstChild("leaderstats") and pl.leaderstats:FindFirstChild("Kills") and pl.leaderstats.Kills.Value or 0
			if ks >= KILL_LIMIT then
				winner = pl.Name
				break
			end
		end
		if winner then break end
		task.wait(1)
	end
	return winner
end

task.wait(2)
while true do
	if #Players:GetPlayers() >= MIN_PLAYERS then
		startLobby()
		local winner = startRound()
		if not winner then
			local top, leaders = -1, {}
			for _, pl in ipairs(Players:GetPlayers()) do
				local ks = pl:FindFirstChild("leaderstats") and pl.leaderstats:FindFirstChild("Kills") and pl.leaderstats.Kills.Value or 0
				if ks > top then
					top, leaders = ks, {pl}
				elseif ks == top then
					table.insert(leaders, pl)
				end
			end
			if #leaders == 1 then winner = leaders[1].Name end
		end

		for _, pl in ipairs(Players:GetPlayers()) do
			local coins = pl:FindFirstChild("Coins")
			if coins then
				if pl.Name == winner then
					coins.Value += 690000
					local w = pl:FindFirstChild("Wins")
					if w then
						w.Value += 1
						setLifetime("Wins", w.Value, pl.UserId)
						incrPeriod("Wins", 1, pl.UserId)
					end
				else
					coins.Value += 10
				end
			end

			local ls = pl:FindFirstChild("leaderstats")
			local roundKills = ls and ls:FindFirstChild("Kills") and ls.Kills.Value or 0
			local lk = pl:FindFirstChild("LifetimeKills")
			if lk and roundKills > 0 then
				lk.Value += roundKills
				setLifetime("Kills", lk.Value, pl.UserId)
				incrPeriod("Kills", roundKills, pl.UserId)
			end
		end

		evEnd:FireAllClients(winner or "")
		broadcastLeader(nil)
		for _, pl in ipairs(Players:GetPlayers()) do
			KillStreaks.Reset(pl)
		end
		AuraService.EndRound()
		task.wait(5)
	else
		task.wait(1)
	end
end
