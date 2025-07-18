-- ServerScriptService/MeleeHandler.lua

local Players     = game:GetService("Players")
local RS          = game:GetService("ReplicatedStorage")
local remotes     = RS:WaitForChild("GameRemotes")

local meleeAttack = remotes:WaitForChild("MeleeAttack")
local meleeResult = remotes:WaitForChild("MeleeResult")
local grantEvent  = remotes:WaitForChild("GrantBullet")

local MELEE_DAMAGE = 101
local RANGE        = 5
local COOLDOWN     = 1.25

-- server‐side debounce tracker
local lastSwing = {}

meleeAttack.OnServerEvent:Connect(function(attacker)
	-- validate attacker
	if not attacker or not attacker.Character then return end

	-- enforce cooldown
	local now = tick()
	if lastSwing[attacker] and now - lastSwing[attacker] < COOLDOWN then
		return
	end
	lastSwing[attacker] = now

	local char = attacker.Character
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- raycast forward
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = { char }
	local ray = workspace:Raycast(root.Position, root.CFrame.LookVector * RANGE, params)

	-- notify client no‐hit by default
	meleeResult:FireClient(attacker, false)

	if ray and ray.Instance then
		local victimChar = ray.Instance:FindFirstAncestorOfClass("Model")
		local victim     = victimChar and Players:GetPlayerFromCharacter(victimChar)
		local hum        = victimChar and victimChar:FindFirstChild("Humanoid")
		if victim and hum and hum.Health > 0 and victim ~= attacker then
			-- apply damage
			hum:TakeDamage(MELEE_DAMAGE)
			meleeResult:FireClient(attacker, true)

			-- if killed
			if hum.Health <= 0 then
				-- increment kills & coins
				local stats = attacker:FindFirstChild("leaderstats")
				if stats then
					local k = stats:FindFirstChild("Kills")
					if k then k.Value = k.Value + 1 end
					local c = stats:FindFirstChild("Coins")
					if c then c.Value = c.Value + 10 end
				end

				-- refund 1 bullet
				local ammo = attacker:FindFirstChild("Ammo")
				if ammo then
					ammo.Value = ammo.Value + 1
					grantEvent:FireClient(attacker)
				end
			end
		end
	end
end)
