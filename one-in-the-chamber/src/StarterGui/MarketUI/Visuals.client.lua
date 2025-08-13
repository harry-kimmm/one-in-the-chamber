local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EasyVisuals = require(ReplicatedStorage:WaitForChild("EasyVisuals"))
local Frame = script.Parent:WaitForChild("MarketFrame")
local Button = script.Parent:WaitForChild("OpenMarketButton")


EasyVisuals.new(Frame, "RainbowOutline", 75, 4)
EasyVisuals.new(Button, "RainbowOutline", 75, 3)
