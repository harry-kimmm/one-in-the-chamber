-- StarterPlayerScripts/ShiftLockController.lua
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

-- Safely unbind any old ShiftLock step
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
		-- lock the mouse at center…
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
		-- …and rotate the root to face the camera’s Y angle
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

-- Round events
BeginRound.OnClientEvent:Connect(function()
	active = true
	if player.Character then
		-- slight delay to ensure camera is ready
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

-- Respawn handling
player.CharacterAdded:Connect(function(char)
	if active then
		-- once character fully loads, re‑apply ShiftLock
		char:WaitForChild("HumanoidRootPart")
		task.defer(function() applyShiftLock(char) end)
	end
end)
