function onHit(hit)
if hit.Parent.Head ~= nil then
if script.Parent.Parent.Humanoid.Health == 0 then
local a = game.Players:FindFirstChild(hit.Parent.Name)
if a ~= nil then
a.leaderstats.Cash.Value = a.leaderstats.Cash.Value + 5
script.Parent.Parent:remove()
else
end
end
end
end
script.Parent.Touched:connect(onHit)