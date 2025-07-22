local b = script.Parent

-- exit

b.MouseButton1Click:Connect(function()
	script.Parent.Parent:TweenPosition(UDim2.new(0.5, 0,1.5, 0), "Out", "Elastic", 1)
end)