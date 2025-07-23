script.Parent.MouseEnter:Connect(function()
	for i = 0,-5,-5 do
		wait()
		script.Parent.Rotation = i
	end
end)

script.Parent.MouseLeave:Connect(function()
	for i = -5,0,5 do
		wait()
		script.Parent.Rotation = i
	end
end)