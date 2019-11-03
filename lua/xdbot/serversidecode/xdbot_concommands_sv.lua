--Serverside console commands
util.AddNetworkString( "xdbotgotolookmsg" )

local function xdbotgotolookmsg_callback( len, ply )
	print( "xdbotgotolookmsg_callback", len, ply )
	if not ply:IsAdmin() then
		print( "xdbotgotolookmsg_callback", ply .. "is not admin!" )
		return
	end
	if not cvars.Bool( "sv_cheats" ) then
		print( "xdbotgotolookmsg_callback", "sv_cheats disabled!" )
		return
	end
	local tr = ply:GetEyeTrace()
	local pos = tr.HitPos
	local controllers = ents.FindByClass( "xdbot_controller_*" )
	for k,v in pairs(controllers) do
		v:GotoLookpos( pos )
	end
end

local function assigncontrollertoplr( ply, personatablename, realplayer )

	if ply.ControllerEnt then
		print("assigncontrollertoplr","ply.ControllerEnt entity already exist!")
		return
	end

	local controllerlua = "xdbot_controller_base"
	local willingcontroller = "xdbot_controller_" .. string.lower( GAMEMODE_NAME )
	if file.Exists( "entities/" .. willingcontroller .. ".lua", "LUA" ) then
		controllerlua = willingcontroller
	else
		print("Warning! " .. willingcontroller .. " not found. Using base controller. Bot might not work properly in this gamemode.")
	end

	ply.ControllerEnt = ents.Create( controllerlua )
	if not ply.ControllerEnt then
		print("assigncontrollertoplr","ply.ControllerEnt FAILED!")
		return
	end
	ply.ControllerEnt:SetPersona( personatablename )
	ply.ControllerEnt:SetHostBot( ply )
	ply.ControllerEnt:Spawn()
	-- When it spawns initially, it doesn't have bot.isXDBot yet, so it skips special hook to fix player model and spawns as kleiner
	--ply.ControllerEnt:HandlePlayermodelOnRespawn()
	ply:SetNWBool( "isXDBot", true )
	--if not realplayer then hook.Run( "PlayerSetModel", ply ) end

end

net.Receive( "xdbotgotolookmsg", xdbotgotolookmsg_callback )

util.AddNetworkString( "xdbotbecomebotmsg" )

local function xdbotbecomebotmsg_callback( len, ply )
	assigncontrollertoplr( ply, "_default_persona", true )
end

net.Receive( "xdbotbecomebotmsg", xdbotbecomebotmsg_callback )

local function xdbot_add( ply, cmd, args )

	if not ( #player.GetAll() < game.MaxPlayers() ) then
		print("Server is full! Can't create bot!")
		return
	end

	PrintTable(args)

	local personatable = list.Get( "XDBot_Personas" )
	local persona = personatable[ args[1] or "_default_persona" ]

	if not persona then
		print( "Error!", args[1], "persona not found!")
		return
	end

	local personaname = persona.Name or args[1]

	local bot = player.CreateNextBot( personaname )
	if not bot then
		print("Error! bot is NULL!")
		return
	end

	assigncontrollertoplr( bot, args[1], false )
end

concommand.Add( "xdbot_add", xdbot_add, nil, "Spawn a bot. Optionally specify persona name as argument", { FCVAR_DONTRECORD } )


CreateConVar( "xdbot_drawpath", "0", FCVAR_CHEAT, "Show bot paths for debugging" )
CreateConVar( "xdbot_huntplayers", "0", FCVAR_ARCHIVE, "Attack players if gamemode specific controller doesn\'t have specific player relations handler" )

