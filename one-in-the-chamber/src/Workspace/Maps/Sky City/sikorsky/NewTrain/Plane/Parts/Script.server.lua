position = script.Parent.Engine.Position
local frame = Instance.new("CFrameValue")
frame.Name = "OriginCFrame"
frame.Value = script.Parent.Engine.CFrame
frame.Parent = script.Parent

local object = Instance.new("ObjectValue")
object.Value = script.Parent.Parent.Parent

seat = script.Parent.Seat

function onSitUp(child, hopper, plane)

	if child.Parent == nil then
		hopper.Parent = nil
	end
end

function onChildAdded(part)
	if part.className == "Weld" then

		

		local torso = part.Part1
		if torso ~= nil then

			local char = torso.Parent
			local player = game.Players:GetPlayerFromCharacter(char)
			if player ~= nil then
				part.C1 = CFrame.fromEulerAnglesXYZ(80.1 ,0 ,0) * CFrame.new(0, 0, 0.6)
				local hopper = game.Lighting.Sikorsky:clone()
				hopper.Parent = player.Backpack
				part.AncestryChanged:connect(function(child) onSitUp(child, hopper, script.Parent.Parent) end) 
			end

			

			local parent = torso.Parent
			if parent ~= nil then
				script.Parent.Parent.Parent = parent
				while true do
					wait(2)
					local pos = script.Parent.Engine.Position
					if (position - pos).magnitude > 30 then
						if object.Value ~= nil then
							object.Value.Regen.Value = 1
							wait(.5)
							object.Value.Regen.Value = 0
							object.Value = nil
						end
					break end
				end
				while true do
					print("Loop")
					wait(2)
					if part == nil then
						script.Parent.Parent.Parent = game.Workspace
						script.Parent.Parent:MakeJoints()
					break end
				end
			end
		end
	end
end
seat.ChildAdded:connect(onChildAdded)
