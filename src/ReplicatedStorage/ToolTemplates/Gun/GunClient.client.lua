local tool             = script.Parent
local Players          = game:GetService("Players")
local RS               = game:GetService("ReplicatedStorage")
local Debris           = game:GetService("Debris")
local ContentProvider  = game:GetService("ContentProvider")

-- remotes & player
local fireEvent        = RS:WaitForChild("GameRemotes"):WaitForChild("FireBullet")
local grantEvent       = RS:WaitForChild("GameRemotes"):WaitForChild("GrantBullet")
local player           = Players.LocalPlayer
local Mouse            = player:GetMouse()
local ammoVal          = player:WaitForChild("Ammo")

-- VFX
local fxFolder         = RS:WaitForChild("Effects")
local muzzleEffects    = fxFolder:WaitForChild("MuzzleFlash")
local handle           = tool:WaitForChild("Handle")
local muzzleAttachment = handle:WaitForChild("MuzzleAttachment")
local shootSound       = handle:WaitForChild("ShootSound")

local MAX_RANGE = 500

-- your Animation objects under the tool:
local equipAnim = tool:WaitForChild("EquipAnimation")
local fireAnim  = tool:WaitForChild("FireAnimation")

-- preload the assets so first play is never sluggish
ContentProvider:PreloadAsync({ equipAnim, fireAnim })

-- will hold our tracks
local equipTrack, fireTrack

-- set up both tracks once the character appears
local function setupTracks(char)
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- ensure R15 Animator
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	-- load draw‑clip
	if not equipTrack or equipTrack.Parent ~= animator then
		equipTrack = animator:LoadAnimation(equipAnim)
		equipTrack.Priority = Enum.AnimationPriority.Action
		equipTrack.Looped   = false
	end

	-- load shot‑clip
	if not fireTrack or fireTrack.Parent ~= animator then
		fireTrack = animator:LoadAnimation(fireAnim)
		fireTrack.Priority = Enum.AnimationPriority.Action
		fireTrack.Looped   = false
	end
end

-- whenever you respawn, hook up the tracks
player.CharacterAdded:Connect(setupTracks)
if player.Character then
	setupTracks(player.Character)
end

-- EQUIP: play draw‑clip at 2× speed, disable shooting for 0.25s
tool.Equipped:Connect(function()
	tool.Enabled = false
	if equipTrack then
		equipTrack:Play(0.1, 1, 1.5)  -- fadeTime=0.1, weight=1, speed=2×
	end
	delay(0.3, function()
		tool.Enabled = true
	end)
end)

-- UNEQUIP: cancel either clip if still playing, re‑enable tool
tool.Unequipped:Connect(function()
	if equipTrack and equipTrack.IsPlaying then
		equipTrack:Stop(0)
	end
	if fireTrack and fireTrack.IsPlaying then
		fireTrack:Stop(0)
	end
	tool.Enabled = true
end)

-- CLICK: play shot‑clip then your existing fire logic
tool.Activated:Connect(function()
	if not tool.Enabled then return end
	if ammoVal.Value <= 0 then return end

	-- play your fire animation
	if fireTrack then
		fireTrack:Play()
	end

	-- sound + server hit
	shootSound:Play()
	fireEvent:FireServer(Mouse.Hit.Position)

	-- muzzle flash
	for _, e in ipairs(muzzleEffects:GetChildren()) do
		if e:IsA("ParticleEmitter") then
			local em = e:Clone()
			em.Parent = muzzleAttachment
			em:Emit(1)
			Debris:AddItem(em, em.Lifetime.Max)
		end
	end

end)

-- no‑op grantEvent
grantEvent.OnClientEvent:Connect(function() end)
