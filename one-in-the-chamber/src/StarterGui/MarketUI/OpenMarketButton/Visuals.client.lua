local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EasyVisuals = require(ReplicatedStorage:WaitForChild("EasyVisuals"))
local Text = script.Parent:WaitForChild("TextLabel")


EasyVisuals.new(Text, "Rainbow", 0.5)
