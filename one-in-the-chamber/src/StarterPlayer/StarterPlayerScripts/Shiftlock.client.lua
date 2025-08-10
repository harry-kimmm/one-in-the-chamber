print("[ShiftLock] Controller loaded")

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local RS         = game:GetService("ReplicatedStorage")

local player     = Players.LocalPlayer
local remotes    = RS:WaitForChild("GameRemotes")
local BeginRound = remotes:WaitForChild("BeginRound")
local EndRound   = remotes:WaitForChild("EndRound")
local StartLobby = remotes:WaitForChild("StartLobby")

local stateFolder = RS:WaitForChild("RoundState")
local phaseVal    = stateFolder:WaitForChild("Phase")

local active = false

local function clearBinding()
	pcall(function()
		RunService:UnbindFromRenderStep("ShiftLock")
	end)
end

local function applyShiftLock(char)
	clearBinding()
	local hum  = char:WaitForChild("Humanoid")
	local root = char:WaitForChild("HumanoidRootPart")
	hum.AutoRotate   = false
	hum.CameraOffset = Vector3.new(1.75, 0, 0)
	RunService:BindToRenderStep("ShiftLock", Enum.RenderPriority.Camera.Value, function()
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
		local _, y, _ = workspace.CurrentCamera.CFrame:ToEulerAnglesYXZ()
		root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, y, 0)
	end)
end

local function removeShiftLock()
	clearBinding()
	local char = player.Character
	if char then
		local hum = char:FindFirstChild("Humanoid")
		if hum then
			hum.AutoRotate   = true
			hum.CameraOffset = Vector3.new(0, 0, 0)
		end
	end
	UIS.MouseBehavior = Enum.MouseBehavior.Default
end

BeginRound.OnClientEvent:Connect(function()
	active = true
	if player.Character then
		task.defer(function() applyShiftLock(player.Character) end)
	end
end)

EndRound.OnClientEvent:Connect(function()
	active = false
	removeShiftLock()
end)

StartLobby.OnClientEvent:Connect(function()
	active = false
	removeShiftLock()
end)

player.CharacterAdded:Connect(function(char)
	if active then
		char:WaitForChild("HumanoidRootPart")
		task.defer(function() applyShiftLock(char) end)
	end
end)

local function syncFromPhase()
	local shouldBeActive = (phaseVal.Value == "Round")
	if shouldBeActive and not active then
		active = true
		if player.Character then
			task.defer(function() applyShiftLock(player.Character) end)
		end
	elseif not shouldBeActive and active then
		active = false
		removeShiftLock()
	end
end

syncFromPhase()
phaseVal.Changed:Connect(syncFromPhase)
