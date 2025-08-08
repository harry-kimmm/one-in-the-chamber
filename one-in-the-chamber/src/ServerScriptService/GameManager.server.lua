-- GameManager (ServerScriptService/GameManager)
print("[GameManager] loaded")

local Players              = game:GetService("Players")
local RS                   = game:GetService("ReplicatedStorage")
local DataStoreService     = game:GetService("DataStoreService")
local ServerScriptService  = game:GetService("ServerScriptService")

-- Services/Modules
local KillStreaks  = require(ServerScriptService:WaitForChild("KillStreaks"))
local AuraService  = require(ServerScriptService:WaitForChild("AuraService"))

-- Remotes
local remotes         = RS:WaitForChild("GameRemotes")
local evLobby         = remotes:WaitForChild("StartLobby")
local evRound         = remotes:WaitForChild("StartRound")
local evEnd           = remotes:WaitForChild("EndRound")
local evBeginRound    = remotes:WaitForChild("BeginRound")
local evProfileToggle = remotes:WaitForChild("ProfileToggle")

-- First-place UI update (created if missing)
local firstPlaceEvent = remotes:FindFirstChild("FirstPlaceUpdate")
if not firstPlaceEvent then
	firstPlaceEvent = Instance.new("RemoteEvent")
	firstPlaceEvent.Name = "FirstPlaceUpdate"
	firstPlaceEvent.Parent = remotes
end

-- DataStores for leaderboards
local winsDS = {
	Lifetime = DataStoreService:GetOrderedDataStore("Leaderboard_Wins_Lifetime"),
	Weekly   = DataStoreService:GetOrderedDataStore("Leaderboard_Wins_Weekly"),
	Daily    = DataStoreService:GetOrderedDataStore("Leaderboard_Wins_Daily"),
}
local killsDS = {
	Lifetime = DataStoreService:GetOrderedDataStore("Leaderboard_Kills_Lifetime"),
	Weekly   = DataStoreService:GetOrderedDataStore("Leaderboard_Kills_Weekly"),
	Daily    = DataStoreService:GetOrderedDataStore("Leaderboard_Kills_Daily"),
}

-- Game content
local toolTemplates    = RS:WaitForChild("ToolTemplates")
local HUB_SPAWNS       = workspace:WaitForChild("Hub"):WaitForChild("SpawnPoints")
local MAPS_FOLDER      = workspace:WaitForChild("Maps")

-- Config
local MIN_PLAYERS = 1
local LOBBY_TIME  = 10
local ROUND_TIME  = 10
local KILL_LIMIT  = 10

-- State
local currentPhase     = "None"
local currentMapSpawns = HUB_SPAWNS
local lastLeader       = nil  -- Player or nil

-- Utils
local function updateRank(ds, userId, value)
	pcall(function()
		ds:SetAsync(tostring(userId), value)
	end)
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

-- First-place (unique) computation
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
		-- Client should: show "You are in first place!" label if isLeader==true; otherwise hide.
	end
end

-- Phases
local function startLobby()
	currentPhase     = "Lobby"
	currentMapSpawns = HUB_SPAWNS
	lastLeader       = nil
	broadcastLeader(nil) -- hide label for everyone

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

	-- reset round kills
	for _, pl in ipairs(Players:GetPlayers()) do
		local ls = pl:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild("Kills") then
			ls.Kills.Value = 0
		end
	end

	-- pick map
	local maps  = MAPS_FOLDER:GetChildren()
	local chosen = maps[math.random(1, #maps)]
	currentMapSpawns = chosen:WaitForChild("SpawnPoints")
	evBeginRound:FireAllClients(chosen.Name)

	-- prep players
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

	-- enable aura tracking
	AuraService.BeginRound()

	-- initial leader push
	lastLeader = nil
	broadcastLeader(computeUniqueLeader())

	-- round loop
	local winner
	for t = ROUND_TIME, 1, -1 do
		evRound:FireAllClients(t)

		-- announce leader changes (unique only)
		broadcastLeader(computeUniqueLeader())

		-- win condition
		for _, pl in ipairs(Players:GetPlayers()) do
			local ks = pl:FindFirstChild("leaderstats")
				and pl.leaderstats:FindFirstChild("Kills")
				and pl.leaderstats.Kills.Value or 0
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

-- Main loop
task.wait(2)
while true do
	if #Players:GetPlayers() >= MIN_PLAYERS then
		startLobby()
		local winner = startRound()

		-- tie-breaker if no winner
		if not winner then
			local top, leaders = -1, {}
			for _, pl in ipairs(Players:GetPlayers()) do
				local ks = pl:FindFirstChild("leaderstats")
					and pl.leaderstats:FindFirstChild("Kills")
					and pl.leaderstats.Kills.Value or 0
				if ks > top then
					top, leaders = ks, {pl}
				elseif ks == top then
					table.insert(leaders, pl)
				end
			end
			if #leaders == 1 then winner = leaders[1].Name end
		end

		-- award & persist
		for _, pl in ipairs(Players:GetPlayers()) do
			local coins = pl:FindFirstChild("Coins")
			if coins then
				if pl.Name == winner then
					coins.Value += 690000
					local w = pl:FindFirstChild("Wins")
					if w then
						w.Value += 1
						local u = pl.UserId
						updateRank(winsDS.Lifetime, u, w.Value)
						updateRank(winsDS.Weekly,   u, w.Value)
						updateRank(winsDS.Daily,    u, w.Value)
					end
				else
					coins.Value += 10
				end
			end
			local ls = pl:FindFirstChild("leaderstats")
			local ks = ls and ls:FindFirstChild("Kills") and ls.Kills.Value or 0
			local lk = pl:FindFirstChild("LifetimeKills")
			if lk then
				lk.Value += ks
				local u = pl.UserId
				updateRank(killsDS.Lifetime, u, lk.Value)
				updateRank(killsDS.Weekly,   u, lk.Value)
				updateRank(killsDS.Daily,    u, lk.Value)
			end
		end

		-- end round
		evEnd:FireAllClients(winner or "")

		-- hide first place label for everyone
		broadcastLeader(nil)

		-- reset streaks
		for _, pl in ipairs(Players:GetPlayers()) do
			KillStreaks.Reset(pl)
		end

		-- disable aura for intermission
		AuraService.EndRound()

		task.wait(5)
	else
		task.wait(1)
	end
end
