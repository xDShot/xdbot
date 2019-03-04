local function isxdsbot( ply )
	return ply:GetNWBool( "isXDBot" ) and ply.ControllerEnt and ply:IsBot()
end

local meta = FindMetaTable( "Player" )
if not meta then return end

meta.xddold_GetInfoNum = meta.xddold_GetInfoNum or meta.GetInfoNum
function meta:GetInfoNum( cVarName, default )
	if isxdsbot( self ) and cVarName == "cl_playerskin" then
		return self.ControllerEnt.Personatable.Skin or 0
	else
		return meta.xddold_GetInfoNum( self, cVarName, default )
	end
end

meta.xddold_GetInfo = meta.xddold_GetInfo or meta.GetInfo
function meta:GetInfo( cVarName )
	if not isxdsbot( self ) then
		return meta.xddold_GetInfo( self, cVarName )
	else
		if cVarName == "cl_playermodel" then
			return self.ControllerEnt.Personatable.Model or "kleiner"
		elseif cVarName == "cl_playerbodygroups" then
			return self.ControllerEnt.Personatable.Bodygroups or "0"
		elseif cVarName == "cl_weaponcolor" then
			return self.ControllerEnt.Personatable.Weaponcolor or "0.30 1.80 2.10"
		elseif cVarName == "cl_playercolor" then
			return self.ControllerEnt.Personatable.Playercolor or "0.24 0.34 0.41"
		else
			return meta.xddold_GetInfo( self, cVarName )
		end
	end
end
