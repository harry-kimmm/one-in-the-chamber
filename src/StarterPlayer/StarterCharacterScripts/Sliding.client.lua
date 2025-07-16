local UIS = game:GetService("UserInputService")
local char = script.Parent

local slideAnim = Instance.new("Animation")
slideAnim.AnimationId = script:WaitForChild("SlideAnim").AnimationId

local keybind = Enum.KeyCode.X
local canslide = true

UIS.InputBegan:Connect(function(input, gameprocessed)
	if gameprocessed then return end
	if not canslide then return end
	if input.KeyCode == keybind then
		canslide = false
		local playAnim = char:WaitForChild("Humanoid"):LoadAnimation(slideAnim)
		playAnim:Play()
		local slide = Instance.new("BodyVelocity")
		slide.MaxForce = Vector3.new(1,0,1) * 30000
		slide.Velocity = char.HumanoidRootPart.CFrame.lookVector * 100
		slide.Parent = char.HumanoidRootPart
		for count = 1, 8 do
			wait(0.1)
			slide.Velocity = slide.Velocity * 0.7
		end
		playAnim:Stop()
		slide:Destroy()
		canslide = true
	end
end)
