local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("GameRemotes")
local GetLeaderboard = Remotes:WaitForChild("GetLeaderboard")

local ROW_H = 56
local FONT = Enum.Font.FredokaOne
local SCALE = 1.5
local wired = {}

local function getToggleFrame(gui)
	return gui:FindFirstChild("ToggleFrame") or gui:FindFirstChild("ToggeleFrame")
end

local function styleText(o)
	if o:IsA("TextLabel") or o:IsA("TextButton") then
		o.Font = FONT
		local base = o.TextSize > 0 and o.TextSize or 14
		o.TextScaled = false
		o.TextSize = math.floor(base * SCALE)
	end
end

local function styleAll(container)
	for _, d in ipairs(container:GetDescendants()) do
		styleText(d)
	end
end

local function clearList(list)
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("Frame") and c.Name == "Entry" then c:Destroy() end
	end
	local nd = list:FindFirstChild("NoData"); if nd then nd:Destroy() end
end

local function buildRow(parent, rank, userId, value)
	local f = Instance.new("Frame")
	f.Name = "Entry"
	f.BackgroundTransparency = 0.3
	f.Size = UDim2.new(1,0,0,ROW_H)
	f.LayoutOrder = rank
	f.Parent = parent

	local r = Instance.new("TextLabel", f)
	r.BackgroundTransparency = 1
	r.Size = UDim2.new(0,36,1,0)
	r.Text = tostring(rank)
	styleText(r)

	local img = Instance.new("ImageLabel", f)
	img.BackgroundTransparency = 1
	img.Size = UDim2.new(0,56,0,56)
	img.Position = UDim2.new(0,36,0,0)
	local ok, thumb = pcall(function()
		return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)
	if ok then img.Image = thumb end

	local nameL = Instance.new("TextLabel", f)
	nameL.BackgroundTransparency = 1
	nameL.Size = UDim2.new(1,-36-56-100,1,0)
	nameL.Position = UDim2.new(0,36+56,0,0)
	nameL.TextTruncate = Enum.TextTruncate.AtEnd
	local uname = ""
	pcall(function() uname = Players:GetNameFromUserIdAsync(userId) end)
	nameL.Text = uname ~= "" and uname or ("User "..tostring(userId))
	styleText(nameL)

	local val = Instance.new("TextLabel", f)
	val.BackgroundTransparency = 1
	val.Size = UDim2.new(0,100,1,0)
	val.Position = UDim2.new(1,-100,0,0)
	val.Text = tostring(value)
	styleText(val)
end

local function setCanvas(list)
	local layout = list:FindFirstChildOfClass("UIListLayout")
	local h = layout and layout.AbsoluteContentSize.Y or 0
	list.CanvasSize = UDim2.new(0,0,0,h+8)
end

local function refreshBoard(part, period)
	local gui = part:FindFirstChild("BoardGui"); if not gui then return end
	local list = gui:FindFirstChild("EntryList"); if not list then return end
	clearList(list)

	local statType = (part.Name == "WinsBoard") and "Wins" or "Kills"
	local ok, res = pcall(function()
		return GetLeaderboard:InvokeServer(statType, period, 10)
	end)
	local data = (ok and type(res)=="table") and res or {}

	if #data == 0 then
		local nd = Instance.new("TextLabel", list)
		nd.Name = "NoData"
		nd.BackgroundTransparency = 1
		nd.Size = UDim2.new(1,0,0,ROW_H)
		nd.Text = "No data yet"
		styleText(nd)
	else
		for i,row in ipairs(data) do
			buildRow(list, i, row.userId, row.value)
		end
	end
	setCanvas(list)
end

local function wireBoard(part)
	if wired[part] then return end
	local gui = part:FindFirstChild("BoardGui"); if not gui then return end
	local list = gui:FindFirstChild("EntryList"); if not list then return end
	local toggles = getToggleFrame(gui); if not toggles then return end

	local lb = toggles:FindFirstChild("LifetimeButton")
	local wb = toggles:FindFirstChild("WeeklyButton")
	local db = toggles:FindFirstChild("DailyButton")
	if not (lb and wb and db) then return end

	styleAll(gui)
	wired[part] = true

	lb.MouseButton1Click:Connect(function() refreshBoard(part, "Lifetime") end)
	wb.MouseButton1Click:Connect(function() refreshBoard(part, "Weekly") end)
	db.MouseButton1Click:Connect(function() refreshBoard(part, "Daily") end)

	refreshBoard(part, "Lifetime")
end

for _, inst in ipairs(workspace:GetDescendants()) do
	if inst:IsA("BasePart") and (inst.Name == "WinsBoard" or inst.Name == "KillsBoard") then
		wireBoard(inst)
	end
end
workspace.DescendantAdded:Connect(function(inst)
	if inst:IsA("BasePart") and (inst.Name == "WinsBoard" or inst.Name == "KillsBoard") then
		wireBoard(inst)
	elseif inst:IsA("SurfaceGui") and inst.Name == "BoardGui" then
		local part = inst.Adornee or inst.Parent
		if part and part:IsA("BasePart") and (part.Name == "WinsBoard" or part.Name == "KillsBoard") then
			wireBoard(part)
		end
	end
end)
