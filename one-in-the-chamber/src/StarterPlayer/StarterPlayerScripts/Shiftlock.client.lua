-- StarterPlayerScripts/ShiftLockController.lua

-- Debug startup
print("[ShiftLock] Controller loaded")

local Players       = game:GetService("Players")
local UIS           = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")
local RS            = game:GetService("ReplicatedStorage")

local player        = Players.LocalPlayer
local remotes       = RS:WaitForChild("GameRemotes")
local BeginRound    = remotes:WaitForChild("BeginRound")
local EndRound      = remotes:WaitForChild("EndRound")
local StartLobby    = remotes:WaitForChild("StartLobby")

local active = false

-- Safely unbind any existing ShiftLock binding
local function clearBinding()
	pcall(function()
		RunService:UnbindFromRenderStep("ShiftLock")
	end)
end

-- Apply shift-lock to the given character
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

-- Remove shift-lock and restore defaults
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

-- Handle round start
BeginRound.OnClientEvent:Connect(function()
	active = true
	if player.Character then
		task.defer(function() applyShiftLock(player.Character) end)
	end
end)

-- Handle round end
EndRound.OnClientEvent:Connect(function()
	active = false
	removeShiftLock()
end)

-- Handle lobby start
StartLobby.OnClientEvent:Connect(function()
	active = false
	removeShiftLock()
end)

-- Reapply on respawn if still in a round
player.CharacterAdded:Connect(function(char)
	if active then
		char:WaitForChild("HumanoidRootPart")
		task.defer(function() applyShiftLock(char) end)
	end
end)
