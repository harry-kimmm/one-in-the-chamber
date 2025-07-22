local anim = Instance.new("Animation") anim.AnimationId = "rbxassetid://12515516441" 
local playAnim = script.Parent.Humanoid:LoadAnimation(anim)

script.Parent.Humanoid.StateChanged:Connect(function(_,state)
	if state == Enum.HumanoidStateType.Landed then
		playAnim:Play()
		wait(1)
		playAnim:Stop()
	end

end)
