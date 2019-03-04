-- Both clientside and serverside initialize, do not edit!

if SERVER then AddCSLuaFile() end

local SHAREDCODE = 0
local CLIENTSIDECODE = 1
local SERVERSIDECODE = 2

local function includelua( file, realm )
	if SERVER and realm ~= SERVERSIDECODE then print("AddCSLuaFile", file ) AddCSLuaFile( file ) end
	if realm == SHAREDCODE or ( SERVER and realm == SERVERSIDECODE ) or ( CLIENT and realm == CLIENTSIDECODE ) then include( file ) end
end

local searchdir = "xdbot/clientsidecode/"
local files, dirs = file.Find( searchdir .. "*", "LUA" )
for enumerate, filename in pairs( files ) do
	includelua( searchdir .. filename, CLIENTSIDECODE )
end

searchdir = "xdbot/serversidecode/"
files, dirs = file.Find( searchdir .. "*", "LUA" )
for enumerate, filename in pairs( files ) do
	includelua( searchdir .. filename, SERVERSIDECODE )
end

searchdir = "xdbot/sharedcode/"
files, dirs = file.Find( searchdir .. "*", "LUA" )
for enumerate, filename in pairs( files ) do
	includelua( searchdir .. filename, SHAREDCODE )
end
