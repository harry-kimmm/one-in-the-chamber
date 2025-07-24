-- StarterPlayerScripts/SkyChangeClient.lua

local Lighting         = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChangeSkyEvent    = ReplicatedStorage:WaitForChild("ChangeSkyEvent")

local skyTemplates      = ReplicatedStorage:WaitForChild("SkyTemplates")

ChangeSkyEvent.OnClientEvent:Connect(function(skyName)
	for _, obj in ipairs(Lighting:GetChildren()) do
		if obj:IsA("Sky") then
			obj:Destroy()
		end
	end

	local template = skyTemplates:FindFirstChild(skyName)
	if template and template:IsA("Sky") then
		template:Clone().Parent = Lighting
	else
		warn("Sky template not found:", skyName)
	end
end)
