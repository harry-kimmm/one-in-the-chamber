local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

Players.PlayerAdded:Connect(function(pl)
	-- ensure inventory + equipped values exist
	local inv = pl:FindFirstChild("Inventory") or Instance.new("Folder", pl)
	inv.Name = "Inventory"

	if not pl:FindFirstChild("EquippedAura") then
		local s = Instance.new("StringValue")
		s.Name, s.Value, s.Parent = "EquippedAura", "DefaultAura", pl
	elseif pl.EquippedAura.Value == "" then
		pl.EquippedAura.Value = "DefaultAura"
	end

	-- own DefaultAura by default
	if not inv:FindFirstChild("DefaultAura") then
		local b = Instance.new("BoolValue")
		b.Name, b.Value, b.Parent = "DefaultAura", true, inv
	end
end)
