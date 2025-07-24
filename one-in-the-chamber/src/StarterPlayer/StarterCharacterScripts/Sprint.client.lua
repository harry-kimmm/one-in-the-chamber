local player = game.Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local fx = game.ReplicatedStorage:WaitForChild("Fx")
local WALKSPEED = 12
local RUNSPEED = 24
local lastRun = 0
local direction = 1
local lastPosition = character.PrimaryPart.Position
local uis = game:GetService("UserInputService")
local ts = game:GetService("TweenService")
local rs = game:GetService("RunService")
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Whitelist
params.FilterDescendantsInstances = {workspace.Map}
local SpeedController = require(player:WaitForChild("PlayerScripts"):WaitForChild("SpeedController"))
local speedCtrl = SpeedController.new(humanoid, WALKSPEED, RUNSPEED/WALKSPEED)

uis.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.ButtonL3 then
		speedCtrl:SetSprint(true)
		direction = 1
	end
end)

uis.InputEnded:Connect(function(input, gpe)
	if input.KeyCode == Enum.KeyCode.ButtonL3 then
		speedCtrl:SetSprint(false)
	end
end)

rs.Heartbeat:Connect(function()
	if (character.PrimaryPart.Velocity * Vector3.new(1,0,1)).Magnitude > WALKSPEED * 2 and humanoid.FloorMaterial ~= Enum.Material.Air then
		if tick() - lastRun > 6/RUNSPEED then
			lastRun = tick()
			local step = fx.Dust:Clone()
			step.Parent = workspace.Fx
			step.CFrame = character.PrimaryPart.CFrame * CFrame.new(direction, -3, 0)
			local rayResult = workspace:Raycast(step.Position + Vector3.new(0,1,0), Vector3.new(0,-3,0), params)
			if rayResult then
				step.Attachment.Dust.Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0, rayResult.Instance.Color),
					ColorSequenceKeypoint.new(1, rayResult.Instance.Color)
				}
			end
			step.Attachment.Dust:Emit(10)
			game.Debris:AddItem(step, 1)
			direction = direction * -1
		end
		for i = 1, math.random(1,3) do
			local hb = Instance.new("Part", workspace.Fx)
			hb.Anchored = true
			hb.CanCollide = false
			hb.Transparency = .8
			hb.Name = "hb"
			hb.Material = Enum.Material.SmoothPlastic
			hb.CanQuery = false
			hb.Size = Vector3.new(.07, .07, math.random(4,6))
			local colorRand = math.random(1,3)
			if colorRand == 1 then
				hb.Color = Color3.fromRGB(86, 86, 86)
			else
				hb.Color = Color3.fromRGB(175, 175, 175)
			end
			local dirCFrame = CFrame.new(lastPosition, character.PrimaryPart.Position)
			hb.CFrame = dirCFrame * CFrame.new(math.random(-25,25)/10, math.random(-3,3), math.random(-2,2))
			game.Debris:AddItem(hb, .2)
			ts:Create(hb, TweenInfo.new(.2), {Transparency = 1, Size = Vector3.new(0,0,0), CFrame = hb.CFrame * CFrame.new(0,0,math.random(2,4))}):Play()
		end
	else
		direction = 1
	end
	lastPosition = character.PrimaryPart.Position
end)
