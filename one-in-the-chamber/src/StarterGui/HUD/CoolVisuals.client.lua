local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EasyVisuals = require(ReplicatedStorage:WaitForChild("EasyVisuals"))
local Text = script.Parent:WaitForChild("FirstPlaceLabel")

EasyVisuals.new(Text, "Rainbow", 0.35)