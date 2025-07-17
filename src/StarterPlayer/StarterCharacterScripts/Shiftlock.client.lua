-- StarterPlayerScripts/ShiftLockController.lua
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = RS:WaitForChild("GameRemotes")
local BeginRound = remotes:WaitForChild("BeginRound")
local EndRound = remotes:WaitForChild("EndRound")
local StartLobby = remotes:WaitForChild("StartLobby")

local active = false

local function applyShiftLock(char)
	local hum = char:WaitForChild("Humanoid")
	local root = char:WaitForChild("HumanoidRootPart")
	hum.AutoRotate = false
	hum.CameraOffset = Vector3.new(1.75, 0, 0)
	RunService:BindToRenderStep("ShiftLock", Enum.RenderPriority.Character.Value, function()
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
		local _, y, _ = workspace.CurrentCamera.CFrame:ToEulerAnglesYXZ()
		root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, y, 0)
	end)
end

local function removeShiftLock()
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	if hum then
		hum.AutoRotate = true
		hum.CameraOffset = Vector3.new(0, 0, 0)
	end
	RunService:UnbindFromRenderStep("ShiftLock")
	UIS.MouseBehavior = Enum.MouseBehavior.Default
end

BeginRound.OnClientEvent:Connect(function()
	active = true
	if player.Character then
		applyShiftLock(player.Character)
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
		applyShiftLock(char)
	end
end)
