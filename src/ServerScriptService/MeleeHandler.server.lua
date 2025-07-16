local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local remotes    = RS:WaitForChild("GameRemotes")

local meleeAttack = remotes:WaitForChild("MeleeAttack")
local meleeResult = remotes:WaitForChild("MeleeResult")
local grantEvent  = remotes:WaitForChild("GrantBullet")

local MELEE_DAMAGE = 35
local RANGE        = 5

meleeAttack.OnServerEvent:Connect(function(attacker)
	if not attacker or not attacker.Character then return end
	local char = attacker.Character
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local params = RaycastParams.new()
	params.FilterType               = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {char}
	local ray = workspace:Raycast(root.Position, root.CFrame.LookVector * RANGE, params)

	meleeResult:FireClient(attacker, false)

	if ray and ray.Instance then
		local victimChar = ray.Instance:FindFirstAncestorOfClass("Model")
		local victim     = victimChar and Players:GetPlayerFromCharacter(victimChar)
		local hum        = victimChar and victimChar:FindFirstChild("Humanoid")
		if victim and hum and hum.Health > 0 and victim ~= attacker then
			hum:TakeDamage(MELEE_DAMAGE)
			meleeResult:FireClient(attacker, true)

			if hum.Health <= 0 then
				attacker.leaderstats.Kills.Value += 1
				attacker.Coins.Value            += 10

				local ammo = attacker:FindFirstChild("Ammo")
				if ammo then
					ammo.Value += 1
					grantEvent:FireClient(attacker)
				end
			end
		end
	end
end)
