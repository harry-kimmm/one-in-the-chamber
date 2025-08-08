-- MeleeHandler
local Players             = game:GetService("Players")
local RS                  = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local KillStreaks = require(ServerScriptService:WaitForChild("KillStreaks"))

local remotes      = RS:WaitForChild("GameRemotes")
local meleeAttack  = remotes:WaitForChild("MeleeAttack")
local grantEvent   = remotes:WaitForChild("GrantBullet")

local COOLDOWN   = 1.25
local KILL_COINS = 3
local lastSwing  = {}

meleeAttack.OnServerEvent:Connect(function(attacker, regionCFrame, regionSize)
	if not attacker or not attacker.Character then return end

	local now = tick()
	if lastSwing[attacker] and now - lastSwing[attacker] < COOLDOWN then
		return
	end
	lastSwing[attacker] = now

	local parts      = workspace:GetPartBoundsInBox(regionCFrame, regionSize)
	local hitPlayers = {}

	for _, part in ipairs(parts) do
		local model  = part:FindFirstAncestorOfClass("Model")
		local victim = model and Players:GetPlayerFromCharacter(model)
		local hum    = model and model:FindFirstChild("Humanoid")
		if victim and hum and hum.Health > 0 and victim ~= attacker and not hitPlayers[victim] then
			hitPlayers[victim] = true

			hum.Health = 0

			local stats = attacker:FindFirstChild("leaderstats")
			if stats then
				local k = stats:FindFirstChild("Kills")
				if k then k.Value += 1 end
				local c = stats:FindFirstChild("Coins")
				if c then c.Value += KILL_COINS end
			end

			KillStreaks.AddKill(attacker)

			local ammo = attacker:FindFirstChild("Ammo")
			if ammo then
				ammo.Value += 1
				grantEvent:FireClient(attacker)
			end
		end
	end
end)
