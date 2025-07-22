--3000cLOnEs
--All the bricks must have a diffront name. If you need more the copy from local to the green tipeing.

local w1 = Instance.new("Weld")

w1.Parent = script.Parent.Engine
w1.Part0 = w1.Parent
w1.Part1 = script.Parent.Seat --Chaing this to the name of the brick
w1.C1 = CFrame.fromEulerAnglesXYZ(0.3, 0, 0) * CFrame.new(0, 0, 0) --Chaing this to put the brick in a diffront place