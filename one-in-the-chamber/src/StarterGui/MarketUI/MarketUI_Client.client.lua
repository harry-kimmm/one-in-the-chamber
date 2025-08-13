local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local remotes = RS:WaitForChild("GameRemotes")
local profileToggle = remotes:WaitForChild("ProfileToggle")
local debugEvt = remotes:FindFirstChild("DebugGrantProduct")

local player = Players.LocalPlayer
local ui = script.Parent
ui.ResetOnSpawn = false

local openBtn = ui:WaitForChild("OpenMarketButton")
local frame = ui:WaitForChild("MarketFrame")
local closeBtn = frame:WaitForChild("CloseButton")
local PRODUCT_IDS = {
	Buy100   = 3369574177,
	Buy500   = 3369577483,
	Buy2500  = 3369577481,
	Buy10000 = 3369577480,
}
local canShow = false
openBtn.Visible = false
frame.Visible = false

profileToggle.OnClientEvent:Connect(function(show)
	canShow = show
	openBtn.Visible = show
	if not show then frame.Visible = false end
end)

player.CharacterAdded:Connect(function()
	openBtn.Visible = canShow
	if not canShow then frame.Visible = false end
end)

openBtn.MouseButton1Click:Connect(function()
	frame.Visible = true
end)

closeBtn.MouseButton1Click:Connect(function()
	frame.Visible = false
end)

for btnName, productId in pairs(PRODUCT_IDS) do
	local b = frame:FindFirstChild(btnName)
	if b and b:IsA("TextButton") then
		b.MouseButton1Click:Connect(function()
			if RunService:IsStudio() and debugEvt then
				debugEvt:FireServer(productId)
			else
				MarketplaceService:PromptProductPurchase(player, productId)
			end
		end)
	end
end
