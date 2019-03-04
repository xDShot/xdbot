ENT.Base = "xdbot_controller_base"
ENT.Type = "nextbot"

ENT.Spawnable = false



function ENT:GamemodeThink()

	self:CheckForHealth()
	self:FindGoodies()

	self:EnemyHandle()
	
end



function ENT:DeathThink()
	if self.HostBot:Alive() then
		print( self, "ENT:DeathThink()", "HostBot is actually alive. Why the hell you call me???" )
		return
	end
	self.Goals = {} -- forget everything. Make all over again
	self.GoalMove = nil
	self.TargetMove = nil
	self:TryToRespawn()
end



function ENT:CanPickupEntity( ent )
	return ent.Available
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