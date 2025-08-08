local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")

local MusicFolder   = ReplicatedStorage:WaitForChild("Music")
local HubTracks     = MusicFolder:WaitForChild("HubTracks")
local GameRemotes   = ReplicatedStorage:WaitForChild("GameRemotes")
local evLobby       = GameRemotes:WaitForChild("StartLobby")
local evBeginRound  = GameRemotes:WaitForChild("BeginRound")
local evEndRound    = GameRemotes:WaitForChild("EndRound")

local currentSound
local inLobby = false

local function playTemplate(tpl)
	if currentSound then
		currentSound:Stop()
		currentSound.Parent = MusicFolder
	end
	local s = tpl:Clone()
	s.Parent = SoundService
	s.Looped = true
	s:Play()
	currentSound = s
end

evLobby.OnClientEvent:Connect(function()
	if not inLobby then
		inLobby = true
		local tracks = HubTracks:GetChildren()
		if #tracks > 0 then
			playTemplate(tracks[math.random(1, #tracks)])
		end
	end
end)

evBeginRound.OnClientEvent:Connect(function(mapName)
	inLobby = false
	local m = MusicFolder:FindFirstChild(mapName)
	if m then playTemplate(m) end
end)

evEndRound.OnClientEvent:Connect(function()
	inLobby = false
	if currentSound then
		currentSound:Stop()
		currentSound.Parent = MusicFolder
		currentSound = nil
	end
end)
