ENT.Base = "xdbot_controller_base"
ENT.Type = "nextbot"

ENT.Spawnable = false

DEFINE_BASECLASS( "xdbot_controller_base" )



function ENT:GamemodeThink()
	BaseClass.GamemodeThink( self )
end



function ENT:DeathThink()
	BaseClass.DeathThink( self )
end



function ENT:CanPickupEntity( ent )
	return ent.Available or BaseClass.CanPickupEntity( self, ent )
end



function ENT:FindMedkit()
	local options = {}
    options.entities = {}
    for k, v in pairs( ents.FindByClass( "q3_pickup_*hp" ) ) do
		if v.Available then table.insert( options.entities, v ) end
	end
	for k, v in pairs( ents.FindByClass( "q3_item_health_mega" ) ) do
		if v.Available then table.insert( options.entities, v ) end
	end
	if not options.entities then return nil end
	local medkits = self:FindAndSortEntities( options )
	if medkits then return medkits[1] end
	return nil
end



function ENT:HandlePlayermodelOnRespawn()
	-- Nothing to do here
end
