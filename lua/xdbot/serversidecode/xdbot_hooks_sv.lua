local list = list
local hook = hook

hook.Add( "StartCommand", "HookXDBotControlSV", function( ply, cmd )
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
		ply:SetEyeAngles( eyeangle )
	
		if ply:IsBot() then ply:SetEyeAngles( eyeangle ) end
	
	end -- if ply.isXDBot
end ) -- function( ply, cmd )

hook.Add( "PlayerDisconnected",  "HookXDBotDisconnected", function( ply )
    if ply:GetNWBool( "isXDBot" ) and ply.ControllerEnt then
        ply.ControllerEnt:Remove()
    end
end )


hook.Add( "EntityTakeDamage", "HookXDBotMakeControllerInvincible", function( target, dmg )
    if target.IsXDBotController then
        print("yup that's him")
        dmg:ScaleDamage(0.00)
        return true
    end
end )



-- @TODO this hook doesn't work for bots
hook.Add( "PlayerDeathThink", "HookXDBotPlayerRespawn", function( ply )
    if ply:GetNWBool( "isXDBot" ) and ply.ControllerEnt then
        ply.ControllerEnt:PlayerRespawn()
    end
end )



hook.Add( "Initialize", "HookXDBotInitWeapprefs", function() --@TODO: Maybe another hook? Some of weps could be missed...
    local weapprefs = list.GetForEdit( "XDBot_Weapprefs" ) -- So it's editable

    local function GetKnownPref( swepname )
        -- Recursively go through parent weapons and grab values from known base or base of base or base of base of base or...
        -- @TODO there is a bug when it tries to access to non-existent base, like fa:s base
        local returntable = {}
        local sweptable = weapons.Get( swepname )

        if weapprefs[ sweptable.ClassName ] then
            table.Merge( returntable, weapprefs[ sweptable.ClassName ] )
        elseif sweptable.XDBot_Weapprefs then
            table.Merge( returntable, sweptable.XDBot_Weapprefs )
        elseif sweptable.Base then
            returntable = GetKnownPref( sweptable.Base )
        end

        return returntable
    end

    -- Try to add prefs for other non-listed weapons
    local sweps = weapons.GetList()
    for k, v in pairs(sweps) do

        if not weapprefs[ v.ClassName ] then -- If already exist in list, skip it

            local tmptable = {}

            -- @TODO: Info from TFA, CW and other bases

            if v.XDBot_Weapprefs then
                -- There's Weappref stored inside of SWEP. Grab it.
                table.Merge( tmptable, v.XDBot_Weapprefs )
            else
                -- Recursively go through parent weapons and grab values from known base or base of base or base of base of base or...
                tmptable = GetKnownPref( v.ClassName )
            end

            weapprefs[ v.ClassName ] = {}
            table.Merge( weapprefs[ v.ClassName ], tmptable )

        end
    end

    -- Add all default values that don't exist in table
    for k, v in pairs(weapprefs) do
        local tmptable = {}
        table.Merge( tmptable, XDBOT_GLOBALS.DefaulWeappref )
        table.Merge( tmptable, v )
        table.Merge( v, tmptable )
    end
end )
