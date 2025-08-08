model = script.Parent.Parent.Parent
backup = model:clone()
local debounce = false

function onTouch(part)
	if (part.Name == "Safe") and (debounce == false) and (script.Parent.Count.Value == 0) then
	debounce = true
	wait(2)
	model = backup:clone()
	model.Parent = game.Workspace
	model:makeJoints()
	script.Parent.Count.Value = 1
	debounce = false
	end
end 
script.Parent.Touched:connect(onTouch)