local UIS = game:GetService("UserInputService")
local DefaultFOV = 70
 
local lastTime = tick()
local player = game.Players.LocalPlayer
 
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local run = false
local Track1 
local Track2
	
local runs = char:WaitForChild("Running")
UIS.InputBegan:Connect(function(input,gameprocessed)
	if input.KeyCode == Enum.KeyCode.W then
		if char:FindFirstChild("Ragdoll") then return end
		local now = tick()
		local difference = (now - lastTime)
		
		if difference <= 0.5 then
			
	
			run = true
				
				Track1 = game.Players.LocalPlayer.Character.Humanoid:LoadAnimation(script.Run)
			
			
				
					Track1:Play()
			
			
			
				hum.WalkSpeed = 24.5
				runs.Value = true
				local properties = {FieldOfView = DefaultFOV + 15}
				local Info = TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,0.1)
				local T = game:GetService("TweenService"):Create(game.Workspace.CurrentCamera,Info,properties)
				T:Play()
			
			
				
			
			end
			

		lastTime = tick()
	end
end)
 
UIS.InputEnded:Connect(function(input,gameprocessed)
	if input.KeyCode == Enum.KeyCode.W then
		run = false
	if Track1 then	
			Track1:Stop()
		end	
	
		hum.WalkSpeed = 16
		runs.Value = false
		local properties = {FieldOfView = DefaultFOV}
		local Info = TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,0.1)
		local T = game:GetService("TweenService"):Create(game.Workspace.CurrentCamera,Info,properties)
		T:Play()
 
	end
 
end)
 