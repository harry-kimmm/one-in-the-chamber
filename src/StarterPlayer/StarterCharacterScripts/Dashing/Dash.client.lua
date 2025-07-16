local UIS=game:GetService("UserInputService")
local Player=game.Players.LocalPlayer
local Char=Player.Character or Player.CharacterAdded:Wait()
while Char.Parent==nil do Char.AncestryChanged:Wait() end
local HumRP=Char:WaitForChild("HumanoidRootPart")
local Hum=Char:WaitForChild("Humanoid")
local RollFrontAnim=Hum:LoadAnimation(script:WaitForChild("RollFront"))
local BackRollAnim=Hum:LoadAnimation(script:WaitForChild("BackRoll"))
local LeftRollAnim=Hum:LoadAnimation(script:WaitForChild("RightRoll"))
local RightRollAnim=Hum:LoadAnimation(script:WaitForChild("LeftRoll"))
local DashDebounce=false
local DashingDebounce=false
local CanDoAnything=true
local WKeyDown,AKeyDown,SKeyDown,DKeyDown=false,false,false,false
UIS.InputBegan:Connect(function(input,processed)
	if processed or Char:FindFirstChild("PBSTUN") or Char:FindFirstChild("noJump") then return end
	if CanDoAnything and input.KeyCode==Enum.KeyCode.Q and not DashDebounce and not Char:FindFirstChild("Disabled") then
		DashDebounce=true
		CanDoAnything=false
		delay(0.3,function() CanDoAnything=true end)
		delay(2.5,function() DashDebounce=false end)
		if WKeyDown then
			RollFrontAnim:Play()
			DashingDebounce=true
			delay(0.25,function() DashingDebounce=false end)
			repeat HumRP.Velocity=HumRP.CFrame.LookVector*130 wait(0.1) until not DashingDebounce
		elseif SKeyDown then
			BackRollAnim:Play()
			DashingDebounce=true
			delay(0.25,function() DashingDebounce=false end)
			repeat HumRP.Velocity=HumRP.CFrame.LookVector*-130 wait(0.1) until not DashingDebounce
		elseif DKeyDown then
			LeftRollAnim:Play()
			DashingDebounce=true
			delay(0.25,function() DashingDebounce=false end)
			repeat HumRP.Velocity=HumRP.CFrame.RightVector*145 wait(0.11) until not DashingDebounce
		elseif AKeyDown then
			RightRollAnim:Play()
			DashingDebounce=true
			delay(0.25,function() DashingDebounce=false end)
			repeat HumRP.Velocity=HumRP.CFrame.RightVector*-145 wait(0.11) until not DashingDebounce
		end
	end
end)
local RunService=game:GetService("RunService")
RunService.RenderStepped:Connect(function()
	WKeyDown=UIS:IsKeyDown(Enum.KeyCode.W)
	AKeyDown=UIS:IsKeyDown(Enum.KeyCode.A)
	SKeyDown=UIS:IsKeyDown(Enum.KeyCode.S)
	DKeyDown=UIS:IsKeyDown(Enum.KeyCode.D)
end)
