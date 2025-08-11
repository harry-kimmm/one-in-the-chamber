local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local remotes = RS:WaitForChild("GameRemotes")
local toggleEvt = remotes:WaitForChild("ProfileToggle")

local roundState = RS:WaitForChild("RoundState")
local phaseVal = roundState:WaitForChild("Phase")

local openBtn = script.Parent:WaitForChild("OpenProfileButton")
local frame   = script.Parent:WaitForChild("ProfileFrame")

local sg = script:FindFirstAncestorOfClass("ScreenGui")
if sg then sg.ResetOnSpawn = false end

local showAllowed = false

local function apply()
	openBtn.Visible = showAllowed
	if not showAllowed then
		frame.Visible = false
	end
end

toggleEvt.OnClientEvent:Connect(function(show)
	-- never show during Round even if a stale event fires after respawn
	showAllowed = (show == true) and (phaseVal.Value ~= "Round")
	apply()
end)

phaseVal:GetPropertyChangedSignal("Value"):Connect(function()
	-- hard-hide during Round; otherwise keep whatever server last told us
	if phaseVal.Value == "Round" then
		showAllowed = false
		apply()
	end
end)

-- initialize based on current phase (hide if we joined mid-round)
showAllowed = (phaseVal.Value ~= "Round") and false or false
apply()
