--Hello, camcool12354 here. This script holds the entire model together, remove this if you want the model to "explode".  Have fun! :D--

local model = script.Parent

local part = Instance.new("Part",model)
part.Name = "WeldPart"

part.formFactor = Enum.FormFactor.Custom
part.Size = Vector3.new(0.2,0.2,0.2)

part.TopSurface = Enum.SurfaceType.Smooth
part.BottomSurface = Enum.SurfaceType.Smooth
part.LeftSurface = Enum.SurfaceType.Smooth
part.RightSurface = Enum.SurfaceType.Smooth
part.FrontSurface = Enum.SurfaceType.Smooth
part.BackSurface = Enum.SurfaceType.Smooth

part.Anchored = false
part.CanCollide = false
part.Locked = true
part.Transparency = 1
part.Reflectance = 0
part.Material = Enum.Material.Plastic
part.CFrame = model:GetModelCFrame()

local function Weld(obj)
	for i, child in pairs(obj:GetChildren()) do
		Weld(child)
	end
	if obj:IsA("BasePart") then
		local w = Instance.new("Weld",part)
		w.Name = obj.Name
		w.C0 = part.CFrame:inverse()
		w.C1 = obj.CFrame:inverse()
		w.Part0 = part
		w.Part1 = obj
		obj.Anchored = false
	end
end

Weld(model)
