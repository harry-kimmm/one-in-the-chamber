print("[GameManager] loaded")

local Players         = game:GetService("Players")
local RS              = game:GetService("ReplicatedStorage")

local remotes         = RS:WaitForChild("GameRemotes")
local evLobby         = remotes:WaitForChild("StartLobby")
local evRound         = remotes:WaitForChild("StartRound")
local evEnd           = remotes:WaitForChild("EndRound")
local evBeginRound    = remotes:WaitForChild("BeginRound")

local toolTemplates   = RS:WaitForChild("ToolTemplates")

local HUB_SPAWNS      = workspace:WaitForChild("Hub"):WaitForChild("SpawnPoints")
local MAPS_FOLDER     = workspace:WaitForChild("Maps")

local MIN_PLAYERS     = 1
local LOBBY_TIME      = 10
local ROUND_TIME      = 5
local KILL_LIMIT      = 10

local currentPhase     = "None"
local currentMapSpawns = HUB_SPAWNS


local function broadcastAll(evt, ...)
	evt:FireAllClients(...)
end


local function teleportTo(player, spawns)
	local char = player.Character
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


local function giveLoadout(player)
	if player.Backpack then
		for _, t in ipairs(player.Backpack:GetChildren()) do
			if t:IsA("Tool") then
				t:Destroy()
			end
		end
	end

	for _, key in ipairs({"EquippedRanged", "EquippedMelee"}) do
		local name = player:FindFirstChild(key) and player[key].Value
		if name then
			local tmpl = toolTemplates:FindFirstChild(name)
			if tmpl then
				tmpl:Clone().Parent = player.Backpack
			end
		end
	end
end


local function onCharacterAdded(char)
	local player = Players:GetPlayerFromCharacter(char)
	if not player then return end

	local hum = char:WaitForChild("Humanoid")
	hum.MaxHealth = 100
	hum.Health    = hum.MaxHealth

	local ammo = player:FindFirstChild("Ammo")
	if ammo then
		ammo.Value = (currentPhase == "Round") and 1 or 0
	end

	if currentPhase == "Lobby" then
		teleportTo(player, HUB_SPAWNS)
	elseif currentPhase == "Round" then
		teleportTo(player, currentMapSpawns)
		giveLoadout(player)
	end
end


Players.PlayerAdded:Connect(function(pl)
	pl.CharacterAdded:Connect(onCharacterAdded)
end)

for _, pl in ipairs(Players:GetPlayers()) do
	pl.CharacterAdded:Connect(onCharacterAdded)
	if pl.Character then
		onCharacterAdded(pl.Character)
	end
end


local function startLobby()
	currentPhase     = "Lobby"
	currentMapSpawns = HUB_SPAWNS

	for _, pl in ipairs(Players:GetPlayers()) do
		pl.leaderstats.Kills.Value = 0

		if pl.Backpack then
			for _, t in ipairs(pl.Backpack:GetChildren()) do
				if t:IsA("Tool") then
					t:Destroy()
				end
			end
		end

		if pl.Character then
			for _, t in ipairs(pl.Character:GetChildren()) do
				if t:IsA("Tool") then
					t:Destroy()
				end
			end
		end

		teleportTo(pl, HUB_SPAWNS)

		local ammo = pl:FindFirstChild("Ammo")
		if ammo then
			ammo.Value = 0
		end
	end

	for t = LOBBY_TIME, 1, -1 do
		broadcastAll(evLobby, t)
		wait(1)
	end
end


local function startRound()
	currentPhase = "Round"

	local maps      = MAPS_FOLDER:GetChildren()
	local chosenMap = maps[math.random(1, #maps)]
	currentMapSpawns = chosenMap:WaitForChild("SpawnPoints")

	broadcastAll(evBeginRound, chosenMap.Name)

	for _, pl in ipairs(Players:GetPlayers()) do
		local ammo = pl:FindFirstChild("Ammo")
		if ammo then
			ammo.Value = 1
		end

		if pl.Character then
			local hum = pl.Character:FindFirstChild("Humanoid")
			if hum then
				hum.MaxHealth = 100
				hum.Health    = hum.MaxHealth
			end
		end

		giveLoadout(pl)

		if pl.Character then
			teleportTo(pl, currentMapSpawns)
		end
	end

	local earlyWinner

	for t = ROUND_TIME, 1, -1 do
		broadcastAll(evRound, t)

		for _, pl in ipairs(Players:GetPlayers()) do
			if pl.leaderstats.Kills.Value >= KILL_LIMIT then
				earlyWinner = pl.Name
				break
			end
		end

		if earlyWinner then
			break
		end

		wait(1)
	end

	return earlyWinner
end


wait(2)

while true do
	if #Players:GetPlayers() >= MIN_PLAYERS then
		startLobby()

		local winner = startRound()

		if not winner then
			local maxK, leaders = -1, {}

			for _, pl in ipairs(Players:GetPlayers()) do
				local v = pl.leaderstats.Kills.Value

				if v > maxK then
					maxK, leaders = v, {pl}
				elseif v == maxK then
					table.insert(leaders, pl)
				end
			end

			if #leaders == 1 then
				winner = leaders[1].Name
			end
		end

		for _, pl in ipairs(Players:GetPlayers()) do
			pl.Coins.Value += (pl.Name == winner and 5000 or 50)
		end

		broadcastAll(evEnd, winner or "")

		wait(5)
	else
		wait(1)
	end
end
