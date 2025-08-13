local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local PRODUCTS = {
	[3369574177] = 100,
	[3369577483] = 500,
	[3369577481] = 2500,
	[3369577480] = 10000,
}

local playerStore = DataStoreService:GetDataStore("PlayerData")
local receiptStore = DataStoreService:GetDataStore("PurchaseReceipts")

local function creditCoins(userId, amount)
	local key = tostring(userId)
	local ok, err = pcall(function()
		playerStore:UpdateAsync(key, function(old)
			local d = typeof(old)=="table" and old or {}
			d.coins = (d.coins or 0) + amount
			return d
		end)
	end)
	if not ok then return false end
	local pl = Players:GetPlayerByUserId(userId)
	if pl and pl:FindFirstChild("Coins") then
		pl.Coins.Value += amount
	end
	return true
end

MarketplaceService.ProcessReceipt = function(receipt)
	local amount = PRODUCTS[receipt.ProductId]
	if not amount then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local already
	local ok1, val = pcall(function()
		return receiptStore:GetAsync(receipt.PurchaseId)
	end)
	if ok1 then already = val end
	if already then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local granted = creditCoins(receipt.PlayerId, amount)
	if not granted then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	pcall(function()
		receiptStore:SetAsync(receipt.PurchaseId, true)
	end)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
