while true do
	wait(20)
	script.Parent.MidAttachment.IncomingDots.Enabled=true
	wait(0.5)
	script.Parent.MidAttachment.IncomingDots.Enabled=false
	wait(0.5)
	script.Parent.MidAttachment.Debris:Emit(25)
	script.Parent.MidAttachment.Debris:Emit(15)
	script.Parent.MidAttachment.BlackBurstFog:Emit(10)
	script.Parent.MidAttachment.Circle:Emit(1)
	script.Parent.MidAttachment.Circle2:Emit(1)
	script.Parent.MidAttachment.Blust:Emit(1)
end
