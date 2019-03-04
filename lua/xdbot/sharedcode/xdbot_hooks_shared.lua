hook.Add( "StartCommand", "HookXDBotControlShared", function( ply, cmd )
	--[[
	if ply:GetNWBool( "isXDBot" ) then

		if ply:IsPlayer() and not ply:IsBot() then
			--remove controller if player pressed buttons and give back control to player, so he's no more bot.
			if SERVER and cmd:GetButtons() > 0 then -- @TODO: ignore if ESC, tab, microphone or chat buttons pressed
				ply.ControllerEnt:ReceivedPlyInput()
				return
			end
			-- clear mouse
			cmd:SetMouseX(0)
			cmd:SetMouseY(0)
		end

		cmd:ClearMovement()
		cmd:ClearButtons()

		local cmdbuttons = ply:IsBot() and ply.ControllerEnt.CmdButtons or ply:GetNWInt( "xDBotButtons" ) -- ply.ControllerEnt.CmdButtons
		cmd:SetButtons( cmdbuttons )
		local movevector = ply:IsBot() and ply.ControllerEnt.CmdMove or ply:GetNWVector( "xDBotMove" ) -- ply.ControllerEnt.CmdMove
		cmd:SetForwardMove( movevector.x )
		cmd:SetSideMove( movevector.y )
		cmd:SetUpMove( movevector.z )
		local eyeangle = ply:IsBot() and ply.ControllerEnt.CmdCurAngle or ply:GetNWAngle( "xDBotAngles" )--ply.ControllerEnt.CmdCurAngle
		cmd:SetViewAngles( eyeangle )
	
		if ply:IsBot() then ply:SetEyeAngles( eyeangle ) end
	
	end -- if ply.isXDBot
	--]]
end ) -- function( ply, cmd )
