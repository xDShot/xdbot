XDBOT_GLOBALS = XDBOT_GLOBALS or {}

XDBOT_GLOBALS.DefaulPersona = {
	Name = "xDBot",
	Model = "kleiner",
	Playercolor = "0.24 0.34 0.41",
	Weaponcolor = "0.30 1.80 2.10",
	Bodygroups = "0",
	Skin = "0"
}

XDBOT_GLOBALS.WeapType_None = 0
XDBOT_GLOBALS.WeapType_Melee = 1
XDBOT_GLOBALS.WeapType_Hitscan_Single = 2
XDBOT_GLOBALS.WeapType_Hitscan_Auto = 3
XDBOT_GLOBALS.WeapType_Ironsight = 4
XDBOT_GLOBALS.WeapType_Projectile = 5
XDBOT_GLOBALS.WeapType_Special = 6

XDBOT_GLOBALS.DefaulWeappref = {
	Prim_type = XDBOT_GLOBALS.WeapType_None,
	Prim_damage = 0,
	Prim_range = 0,
	Prim_rate = 0,
	Prim_radius = 0,
	Prim_projspeed = 0,
	Prim_ammotype = "none",
	Sec_type = XDBOT_GLOBALS.WeapType_None,
	Sec_damage = 0,
	Sec_range = 0,
	Sec_rate = 0,
	Sec_radius = 0,
	Sec_projspeed = 0,
	Sec_ammotype = "none",
	MovementSlowdown = 1
}
