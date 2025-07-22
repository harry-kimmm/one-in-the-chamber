script.Parent.MouseEnter:Connect(function()
	script.Parent:TweenSize(UDim2.new(0.073, 0,0.112, 0),"Out","Quad",.1,true)
end)

script.Parent.MouseLeave:Connect(function()
	script.Parent:TweenSize(UDim2.new(0.08, 0,0.127, 0),"Out","Quad",.1,true)
end)