-- BulletHandler (ServerScriptService)
local Players             = game:GetService("Players")
local RS                  = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local KillStreaks = require(ServerScriptService:WaitForChild("KillStreaks"))

local remotes    = RS:WaitForChild("GameRemotes")
local fireEvent  = remotes:WaitForChild("FireBullet")
local grantEvent = remotes:WaitForChild("GrantBullet")

local MAX_RANGE = 500

local function canAct(player)
	if player:GetAttribute("CanAct") ~= true then return false end
	local char = player.Character
	if not char then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then
		return false
	end
	return true
end

fireEvent.OnServerEvent:Connect(function(player, targetPos)
	if not canAct(player) then return end

	local ammo = player:FindFirstChild("Ammo")
	if not (ammo and ammo.Value > 0) then return end

	-- consume on fire (misses cost a bullet)
	ammo.Value -= 1

	local char = player.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end

	local origin    = head.Position
	local direction = (targetPos - origin).Unit * MAX_RANGE

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { char }
	params.FilterType = Enum.RaycastFilterType.Blacklist

	local result = workspace:Raycast(origin, direction, params)
	if result and result.Instance then
		local victimModel = result.Instance:FindFirstAncestorOfClass("Model")
		local hum         = victimModel and victimModel:FindFirstChild("Humanoid")
		local victim      = hum and Players:GetPlayerFromCharacter(victimModel)
		if victim and hum and hum.Health > 0 and victim ~= player then
			-- kill
			hum.Health = 0

			-- stats & coins
			player.leaderstats.Kills.Value += 1
			player.Coins.Value             += 3

			-- kill streak
			KillStreaks.AddKill(player)

			-- refund one bullet on kill
			ammo.Value += 1
			grantEvent:FireClient(player)
		end
	end
end)
