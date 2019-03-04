list.Set( "XDBot_Weapprefs", "weapon_base", XDBOT_GLOBALS.DefaulWeappref )

list.Set( "XDBot_Weapprefs", "weapon_crowbar", {
	Prim_type = XDBOT_GLOBALS.WeapType_Melee,
	Prim_damage = 25,
	Prim_range = 75,
	Prim_rate = 0.4
} )

list.Set( "XDBot_Weapprefs", "weapon_stunstick", {
	Prim_type = XDBOT_GLOBALS.WeapType_Melee,
	Prim_damage = 40,
	Prim_range = 75,
	Prim_rate = 0.8
} )

list.Set( "XDBot_Weapprefs", "weapon_pistol", {
	Prim_type = XDBOT_GLOBALS.WeapType_Hitscan_Single,
	Prim_ammotype = "Pistol",
	Prim_damage = 8,
	Prim_range = 512,
	Prim_rate = 0.3
} )

list.Set( "XDBot_Weapprefs", "weapon_357", {
	Prim_type = XDBOT_GLOBALS.WeapType_Hitscan_Single,
	Prim_ammotype = "357",
	Prim_damage = 75,
	Prim_range = 2048,
	Prim_rate = 1
} )

list.Set( "XDBot_Weapprefs", "weapon_smg1", {
	Prim_type = XDBOT_GLOBALS.WeapType_Hitscan_Auto,
	Prim_ammotype = "SMG1",
	Prim_damage = 11,
	Prim_range = 256,
	Prim_rate = 0.1,
	Sec_type = XDBOT_GLOBALS.WeapType_Projectile,
	Sec_ammotype = "SMG1",
	Sec_damage = 100,
	Sec_range = 128,
	Sec_radius = 64,
	Sec_rate = 1
} )

list.Set( "XDBot_Weapprefs", "weapon_ar2", {
	Prim_type = XDBOT_GLOBALS.WeapType_Hitscan_Auto,
	Prim_ammotype = "AR2",
	Prim_damage = 5,
	Prim_range = 1024,
	Prim_rate = 0.1
} )

list.Set( "XDBot_Weapprefs", "weapon_shotgun", {
	Prim_type = XDBOT_GLOBALS.WeapType_Hitscan_Single,
	Prim_ammotype = "Buckshot",
	Prim_damage = 50,
	Prim_range = 256,
	Prim_rate = 1,
	Sec_type = XDBOT_GLOBALS.WeapType_Hitscan_Single,
	Sec_ammotype = "Buckshot",
	Sec_damage = 100,
	Sec_range = 128,
	Sec_rate = 1
} )

list.Set( "XDBot_Weapprefs", "weapon_crossbow", {
	Prim_type = XDBOT_GLOBALS.WeapType_Hitscan_Single,
	Prim_ammotype = "XBowBolt",
	Prim_damage = 100,
	Prim_range = 1024,
	Prim_rate = 2
} )

list.Set( "XDBot_Weapprefs", "weapon_rpg", {
	Prim_type = XDBOT_GLOBALS.WeapType_Projectile,
	Prim_ammotype = "RPG_Round",
	Prim_damage = 250,
	Prim_range = 2048,
	Prim_rate = 5
} )

list.Set( "XDBot_Weapprefs", "weapon_fists", {
	Prim_type = XDBOT_GLOBALS.WeapType_Melee,
	Prim_damage = 10,
	Prim_range = 48,
	Prim_rate = 0.9
} )

list.Set( "XDBot_Weapprefs", "csgo_baseknife", {
	Prim_type = XDBOT_GLOBALS.WeapType_Melee,
	Prim_damage = 25,
	Prim_range = 64,
	Prim_rate = 0.4,
	Sec_type = XDBOT_GLOBALS.WeapType_Melee,
	Sec_damage = 65,
	Sec_range = 48,
	Sec_rate = 1
} )
