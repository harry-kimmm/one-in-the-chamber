-- StarterCharacterScripts/Sliding.lua
local UIS=game:GetService("UserInputService")
local char=script.Parent
local anim=Instance.new("Animation")
anim.AnimationId=script:WaitForChild("SlideAnim").AnimationId
local key=Enum.KeyCode.C
local ok=true

UIS.InputBegan:Connect(function(input,processed)
	if processed or not ok then return end
	if input.KeyCode==key then
		ok=false
		local track=char:WaitForChild("Humanoid"):LoadAnimation(anim)
		track:Play()
		local v=Instance.new("BodyVelocity")
		v.MaxForce=Vector3.new(1,0,1)*30000
		v.Velocity=char.HumanoidRootPart.CFrame.LookVector*100
		v.Parent=char.HumanoidRootPart
		for i=1,8 do
			wait(0.1)
			v.Velocity=v.Velocity*0.7
		end
		track:Stop()
		v:Destroy()
		wait(1)
		ok=true
	end
end)
