-- xdbot_goto_lookpos
local function xdbot_goto_lookpos( ply, cmd, args )
	if not ( IsValid( ply ) and ply:IsAdmin() ) then return end
	net.Start( "xdbotgotolookmsg" )
	net.SendToServer()
end

concommand.Add( "xdbot_goto_lookpos", xdbot_goto_lookpos, nil, "Forces all bots go to place you are looking at", { FCVAR_CHEAT } )

local function xdbot_becomebot( ply, cmd, args )
	net.Start( "xdbotbecomebotmsg" )
	net.SendToServer()
end

concommand.Add( "xdbot_becomebot", xdbot_becomebot, nil, "Become bot", nil )
