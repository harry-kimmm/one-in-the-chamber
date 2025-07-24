-- ServerScriptService/SkyChangeServer.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChangeSkyEvent    = ReplicatedStorage:WaitForChild("ChangeSkyEvent")
local skyPartsFolder    = workspace:WaitForChild("SkyParts")

for _, part in ipairs(skyPartsFolder:GetChildren()) do
	if part:IsA("BasePart") then
		part.Touched:Connect(function(hit)
			local char = hit.Parent
			local humanoid = char and char:FindFirstChild("Humanoid")
			if humanoid then
				local player = game.Players:GetPlayerFromCharacter(char)
				if player then
					-- tell only that player which sky to use
					ChangeSkyEvent:FireClient(player, part.Name)
				end
			end
		end)
	end
end
