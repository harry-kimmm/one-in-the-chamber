print("[GameManager] loaded")

local Players          = game:GetService("Players")
local RS               = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local remotes          = RS:WaitForChild("GameRemotes")
local evLobby          = remotes:WaitForChild("StartLobby")
local evRound          = remotes:WaitForChild("StartRound")
local evEnd            = remotes:WaitForChild("EndRound")
local evBeginRound     = remotes:WaitForChild("BeginRound")
local evProfileToggle  = remotes:WaitForChild("ProfileToggle")

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

local toolTemplates    = RS:WaitForChild("ToolTemplates")
local HUB_SPAWNS       = workspace:WaitForChild("Hub"):WaitForChild("SpawnPoints")
local MAPS_FOLDER      = workspace:WaitForChild("Maps")

local MIN_PLAYERS = 1
local LOBBY_TIME  = 5
local ROUND_TIME  = 1
local KILL_LIMIT  = 10

local currentPhase     = "None"
local currentMapSpawns = HUB_SPAWNS

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
			root.CFrame = choice.CFrame + Vector3.new(0,3,0)
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
	local pl = Players:GetPlayerFromCharacter(char)
	if not pl then return end
	local hum = char:WaitForChild("Humanoid")
	hum.MaxHealth = 100
	hum.Health    = 100
	local ammo = pl:FindFirstChild("Ammo")
	if ammo then ammo.Value = (currentPhase=="Round") and 1 or 0 end
	if currentPhase=="Lobby" then
		teleportTo(pl,HUB_SPAWNS)
	elseif currentPhase=="Round" then
		teleportTo(pl,currentMapSpawns)
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

local function startLobby()
	currentPhase     = "Lobby"
	currentMapSpawns = HUB_SPAWNS
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
		teleportTo(pl,HUB_SPAWNS)
		local ammo = pl:FindFirstChild("Ammo")
		if ammo then ammo.Value = 0 end
	end
	for t=LOBBY_TIME,1,-1 do
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
	local maps = MAPS_FOLDER:GetChildren()
	local chosen = maps[math.random(1,#maps)]
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
		if pl.Character then teleportTo(pl,currentMapSpawns) end
	end
	local winner
	for t=ROUND_TIME,1,-1 do
		evRound:FireAllClients(t)
		for _, pl in ipairs(Players:GetPlayers()) do
			local ks = pl:FindFirstChild("leaderstats") 
				and pl.leaderstats:FindFirstChild("Kills")
			if ks and ks.Value >= KILL_LIMIT then
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
				local ks = pl:FindFirstChild("leaderstats")
					and pl.leaderstats:FindFirstChild("Kills")
					and pl.leaderstats.Kills.Value or 0
				if ks > top then
					top, leaders = ks, {pl}
				elseif ks == top then
					table.insert(leaders,pl)
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
		evEnd:FireAllClients(winner or "")
		task.wait(5)
	else
		task.wait(1)
	end
end
