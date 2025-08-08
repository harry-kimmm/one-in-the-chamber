local boom = false

function createExplosion(position)

explosion = Instance.new("Explosion")
explosion.Position = position
explosion.BlastRadius = 12
explosion.Parent = game.Workspace

end

function onTouch(part)
	if boom == true then return end
	if (part.Name == "Rocket") or (part.Name == "Safe") or (part.Parent.Parent.Parent == script.Parent) or (part.Parent:findFirstChild("Humanoid")) then return end
	if (script.Parent.Parts.Tip.Velocity.x > 50) or (script.Parent.Parts.Tip.Velocity.x < -50) or (script.Parent.Parts.Tip.Velocity.z > 50) or (script.Parent.Parts.Tip.Velocity.z < -50) then
	boom = true
	createExplosion(script.Parent.Parts.Engine.Position)
	script.Parent:BreakJoints()
	local stuff = script.Parent:children()
	for i=1,#stuff do
		if stuff[i].Name == "BodyKit" or
		stuff[i].Name == "Parts" then
		local parts = stuff[i]:children()
			for p = 1, #parts do
				if parts[p].className == "Part" then
				local velo = Instance.new("BodyVelocity")
				velo.maxForce = Vector3.new(9.9e+036, 9.9e+036, 9.9e+036)
				velo.velocity = Vector3.new(math.random(-15,15),math.random(-15,15),math.random(-15,15))
				velo.Parent = parts[p]
				end
			end
		end
	end
	wait(4)
	script.Parent:remove()
	end
end

script.Parent.Parts.Tip.Touched:connect(onTouch)
