ENT.Base = "base_nextbot"
ENT.Type = "nextbot"

ENT.Spawnable = false



function ENT:Initialize()
	print(self, "Initialize()")

	-- Override default values fields if they exist in persona table
	local tmptable = {}
	table.Merge( tmptable, XDBOT_GLOBALS.DefaulPersona )

	if self.Personatable then
		table.Merge( tmptable, self.Personatable )
	else
		print(self, "ENT:Initialize", "Warning: there is no self.Personatable. Setting default values")
	end

	table.Merge( self.Personatable, tmptable )

	self:SetModel( "models/player/kleiner.mdl" )
	self:SetNoDraw( true )
	self:DrawShadow( false )
	self:SetSolid( SOLID_NONE )
	self:SetCollisionBounds( Vector(-16,-16,0), Vector(16,16,36) )
	self.IsXDBotController = true

	self.GoalAim = nil
	self.GoalMove = nil

	self.TargetAim = nil
	self.TargetMove = nil

	self.ShouldMove = false
	self.ShouldMoveCrouch = false
	self.ShouldMoveJump = false
	self.ShouldMoveForward = false

	self.PreciseMove = false

	self.BypassDir = nil

	self.FollowTarget = nil
	self.CollectTarget = nil
	self.UseTarget = nil
	-- Possible states:
	-- "move", "chase", "collect", "findmedkit", "camp", "use", "kill", "heal", "objective", "antistuck", "follow", "hunt"
	self.State = "none"

	self.CurrentEnemy = nil
	self.SeeEnemy = 0 -- 0 can't see, 1 see head, 2 see body, 3 see legs
	self.EnemySeenLastTime = CurTime()
	self.EnemySeenInterval = 5 -- seconds
	self.EnemySeenLastPos = nil

	self.ShouldAttack = false

	self.KeyCrouch = false
	self.keyJump = false
	self.keyUse = false
	self.KeySpeed = false
	self.KeyAttack1 = false
	self.KeyAttack2 = false

	self.Path = nil -- PathFollower goes here
	self.PathOptions = {}

	self.CmdButtons = 0

	self.CmdMove = Vector()
	self.CmdCurAngle = Angle(0,0,0)
	self.CmdTargetAngle = Angle(0,0,0)
	self:SetHealth(99999)
	self:SetMaxHealth(99999)

	self.StuckCheckInterval = 1 -- seconds
	self.StuckCheckDistance = 32
	self.StuckCheckDistance2 = self.StuckCheckDistance * self.StuckCheckDistance
	self.StuckCheckPos = Vector()
	self.StuckCheckTime = CurTime()
	self.StuckBypassPos = nil
	self.StuckStatus = 0 -- 0 - not stuck; 1 - try ducking; 2 - try jumping; 3 - bypass

	self.NextGamemodeThink = CurTime()
	self.NextGamemodeThinkInterval = 0.5

	print( self, "GamemodeInitialize()" )
	self:GamemodeInitialize()
end



function ENT:GamemodeInitialize()
	-- No need for this gamemode
end



function ENT:SetPersona( persona )
	print(self, "SetPersona", persona )
	self.Personatable = self.Personatable or {}
	local personatable = list.Get( "XDBot_Personas" )

	if not personatable[persona] then
		print( "Error!", persona, "persona not found!")
		return
	end

	table.Merge( self.Personatable, personatable[persona] )
end



function ENT:SetHostBot( bot )
	print(self, "SetHostBot()", bot )
	if not IsValid( bot ) then
		print( self, "SetHostBot()", "Error!", bot, "valid bot host not found!")
		return
	end

	self.HostBot = bot
end



function ENT:ClearStuckStatus()
	self.StuckStatus = 0
	self.StuckBypassPos = nil
	self.StuckCheckPos = self.HostBot:GetPos()
	self.StuckCheckTime = CurTime() + self.StuckCheckInterval
	self.loco:ClearStuck()
end



function ENT:RunBehaviour()
	while ( true ) do
		self:SetPos( self.HostBot:GetPos() )
		self:SetAngles( self.HostBot:GetAngles() )
		self.loco:SetJumpHeight( 48 )
		self.loco:SetDeathDropHeight( 350 )
		self.loco:SetAcceleration(0)
		self.loco:SetDesiredSpeed(0)
		if self.GoalMove then
			self:MoveToPos( self.GoalMove, self.PathOptions )
		else
			self:ClearStuckStatus()
		end
		coroutine.yield()
	end

end


local jumpPenalty = 5
local crouchPenalty = 5
local avoidPenalty = 26
local runPenalty = 0.2
function ENT:ComputePath( path, pos )

	local hostbot = self.HostBot
	local stepheight = hostbot:GetStepSize()

	local duckmins, duckmaxs = hostbot:GetHullDuck()
	local mins, maxs = duckmins + Vector( 0, 0, stepheight ), duckmaxs
	local mask = MASK_PLAYERSOLID
	local collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
	local filter = { hostbot, self } -- Ignore HostBot and self

	local function generator( area, fromArea, ladder, elevator, length )
		if not IsValid( fromArea ) then
			-- first area in path, no cost
			return 0
		else

			if not self.loco:IsAreaTraversable( area ) then
				-- our locomotor says we can't move here
				return -1
			end

			-- compute distance traveled along path so far
			local dist = 0

			if ( IsValid( ladder ) ) then
				dist = ladder:GetLength()
			elseif ( length > 0 ) then
				-- optimization to avoid recomputing length
				dist = length
			else
				dist = ( area:GetCenter() - fromArea:GetCenter() ):Length()
			end

			local cost = dist + fromArea:GetCostSoFar()

			local fromAreaAttributes = fromArea:GetAttributes()

			local teleportattributes = NAV_MESH_RUN + NAV_MESH_DONT_HIDE + NAV_MESH_CLIFF
			if bit.band( fromAreaAttributes, teleportattributes ) > 0 then
				-- Bingo! Completely without any cost!
				return 0
			end

			if bit.band( fromAreaAttributes, NAV_MESH_JUMP ) > 0 then
				-- jumping is slower than flat ground
				cost = cost + jumpPenalty * dist
			end

			if bit.band( fromAreaAttributes, NAV_MESH_CROUCH ) > 0 then
				-- crouching is slower than running
				cost = cost + crouchPenalty * dist
			end

			if bit.band( fromAreaAttributes, NAV_MESH_AVOID ) > 0 then
				-- avoid this area, pick some better
				-- @TODO: ideally, the functor should parse all other possible combinations to
				-- reach the goal, and if it can't find, then use the combination of areas with this area.
				-- For now, we are with penalty as usual
				cost = cost + avoidPenalty * dist
			end

			if bit.band( fromAreaAttributes, NAV_MESH_RUN ) > 0 then
				-- this area has slightly more priority
				cost = cost - runPenalty * dist
			end

			if bit.band( fromAreaAttributes, NAV_MESH_TRANSIENT ) > 0 then
				-- check if it's blocked by something
				-- If so, ignore it
				local x, y = fromArea:GetSizeX() * 0.5, fromArea:GetSizeY() * 0.5
				local zmin, zmax = 0, duckmaxs.z
				local tracestruct = {
					start = fromArea:GetCenter(),
					endpos = fromArea:GetCenter() + Vector(0,0,stepheight),
					mins = Vector(-x,-y,zmin),
					maxs = Vector(x,y,zmax),
					filter = filter,
					mask = MASK_PLAYERSOLID_BRUSHONLY
				}
				local tr = util.TraceHull( tracestruct )
				if tr.Hit then
					-- Something blocks it, ignore it
					print("Something blocks it, ignore it")
					return -1
				end
			end

			-- check height change
			local deltaZ = fromArea:ComputeAdjacentConnectionHeightChange( area )
			if ( deltaZ >= stepheight ) then
				if ( deltaZ >= 48 ) then
					-- too high to reach
					return -1
				end

				-- jumping is slower than flat ground
				cost = cost + jumpPenalty * dist
			elseif ( deltaZ < -359 ) then
				-- too far to drop
				return -1
			end

			local precisearea = bit.band( fromAreaAttributes, NAV_MESH_JUMP ) > 0 or bit.band( fromAreaAttributes, NAV_MESH_PRECISE ) > 0

			if not precisearea then
				local tracestruct = {
					start = fromArea:GetCenter(),
					endpos = area:GetCenter(),
					mins = mins,
					maxs = maxs,
					filter = filter,
					mask = mask,
					collisiongroup = collisiongroup
				}
				local tr = util.TraceHull( tracestruct )
				if tr.Hit then
					-- Something blocks it, increase cost and prefer better path
					local collisionPenalty = 3
					cost = cost + collisionPenalty * dist
				end
			end -- if not precisearea then

			return cost
		end
	end

	path:Compute( self, pos, generator )
end



function ENT:MoveToPos( pos, options )
	options = options or {}
	options.tolerance = options.tolerance or 20

	self.Path = Path( "Follow" )
	self.Path:SetMinLookAheadDistance( options.lookahead or 300 )
	self.Path:SetGoalTolerance( options.tolerance )
	options.maxage = options.maxage or 5
	options.draw = cvars.Bool( "xdbot_drawpath", false )

	self:InvalidatePath()
	self:ComputePath( self.Path, pos )

	if not self.Path:IsValid() then
		self.ShouldMove = false
		return "failed"
	end

	local hostbot = self.HostBot
	local stepheight = hostbot:GetStepSize()

	local duckmins, duckmaxs = hostbot:GetHullDuck()
	local mins, maxs = duckmins + Vector( 0, 0, stepheight ), duckmaxs
	local mask = MASK_PLAYERSOLID
	local collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
	local filter = { hostbot, self } -- Ignore HostBot and self

	while ( self.Path:IsValid() and self.GoalMove ) do

		-- If they set maxage on options then make sure the path is younger than it
		if options.maxage and ( self.Path:GetAge() > options.maxage ) then return "timeout" end

		if options.tolerance and ( self.Path:GetLength() <= options.tolerance ) then
			-- @TODO: separate field to tell that we reached
			self.GoalMove = nil
			return "ok"
		end

		local getpos = hostbot:GetPos()

		self:SetPos( getpos )
		self.Path:Update(self)

		local AllSegments = self.Path:GetAllSegments()

		if not AllSegments then return "failed" end

		local epsilon = 18
		local epsilon2 = epsilon * epsilon
		local epsilon_min = Vector (-16, -16, -48)
		local epsilon_max = Vector (16, 16, 18)

		local CurSegment = self.Path:GetCurrentGoal() or AllSegments[1]

		local CurArea = CurSegment.area -- the area we are currently on
		local closeup = getpos:DistToSqr( CurSegment.pos ) < epsilon2
		local jumparea = bit.band( CurArea:GetAttributes(), NAV_MESH_JUMP ) > 0 or CurSegment.type == 2 or CurSegment.type == 3
		local croucharea = bit.band( CurArea:GetAttributes(), NAV_MESH_CROUCH ) > 0

		-- Jump or Crouch when needed
		if self.StuckStatus == 1 or ( closeup and croucharea ) then
			self.ShouldMoveJump = false
			self.ShouldMoveCrouch = true
		elseif self.StuckStatus == 2 or ( closeup and jumparea ) then
			self.ShouldMoveJump = true
			self.ShouldMoveCrouch = false
		else
			self.ShouldMoveJump = false
			self.ShouldMoveCrouch = false
		end

		-- Draw the path (only visible on listen servers or single player)
		if ( options.draw ) then self.Path:Draw() end

		-- Detect stuck. 'true' to tell that's called from coroutine.
		-- Returns "stuck" if really stuck
		if self:DetectStuck( true ) then return "stuck" end

		self.TargetMove = CurSegment.pos
		self.ShouldMove = true

		coroutine.yield()

	end

	self.ShouldMove = false
	self.ShouldMoveCrouch = false
	self.ShouldMoveJump = false

	self.PreciseMove = false

	self.TargetMove = nil

	return "ok"

end



function ENT:InvalidatePath()
	if self.Path then self.Path:Invalidate() end
end



function ENT:ChangeGoalMove( newpos )
	self:InvalidatePath()
	self.GoalMove = newpos
end



function ENT:Think()
	self:CheckHostBot()

	if not self.HostBot:Alive() then
		self:DeathThink()
		return -- Don't do anything other
	end

	if CurTime() > self.NextGamemodeThink then
		self:GamemodeThink()
		self:EnemyHandle()
		self.NextGamemodeThink = CurTime() + self.NextGamemodeThinkInterval
	end
	
	self:HandleGoalAim()
	self:SwitchToBestWeapon()
	--self:DetectCollision()
	self:InterpolateViewAngle()
	self:HandleMovement()
	self:HandleKeys()
end



local function inrange( value, min, max )
	return (min <= value) and (value <= max)
end
function ENT:VectorInBoxRange( vec, vec_min, vec_max )
	-- Fix the vectors vec_min and vec_max, so that vec_min contains all the smallest values and vec_max all the largest values on all axies
	-- NOTE that this will modify the actual vectors
	OrderVectors( vec_min, vec_max )
	return inrange( vec.x, vec_min.x, vec_max.x ) and inrange( vec.y, vec_min.y, vec_max.y ) and inrange( vec.z, vec_min.z, vec_max.z )
	-- return vec:WithinAABox( vec_min, vec_max )
end



function ENT:DetectStuck( calledfromcoroutine )
	local getpos = self.HostBot:GetPos()
	if self.StuckCheckPos:DistToSqr( getpos ) > self.StuckCheckDistance2 then
		self:ClearStuckStatus()
	elseif CurTime() > self.StuckCheckTime then
		print( self, "STUCK! at", getpos, "to", self.TargetMove )
		if self.StuckStatus < 3 then
			self.StuckStatus = self.StuckStatus + 1
		end
		if self.StuckStatus >= 3 then
			self.StuckBypassPos = getpos + VectorRand() * 128
		end
		self.StuckCheckPos = getpos
		self.StuckCheckTime = CurTime() + self.StuckCheckInterval
		if calledfromcoroutine then return true end -- Returns to coroutine
	end
end



function ENT:GamemodeThink()

	self:CheckForHealth()
	if self.State ~= "findmedkit" then
		self:FindGoodies()
	end

	if IsValid( self.CollectTarget ) and ( self.State == "findmedkit" or self.State == "collect" ) then
		self.PathOptions = nil
		self.GoalMove = self.CollectTarget:GetPos()
		if IsValid( self.CollectTarget:GetOwner() ) then self:ClearCollectState() end --someone picked it already
	else
		self:ClearCollectState()
		self:FindPlayerToFollow()
		
		if IsValid( self.FollowTarget ) then
			self.State = "follow"
			self.GoalMove = self.FollowTarget:GetPos()
			self.PathOptions.tolerance = 100
			self.PathOptions.maxage = 1
			
		else
			self.GoalMove = nil
		end
		
		local navareas = navmesh.GetAllNavAreas()
		local area = navareas[ math.random( 0, #navareas - 1 ) ]
		if area and not self.GoalMove then
			self.GoalMove = area:GetRandomPoint()
		end
	end

end



function ENT:IsTargetFriendly( target )
	local hates = false
	
	if target:IsNPC() and IsValid( target ) then
		hates = target:Disposition( self.HostBot ) == D_HT
	elseif target:IsPlayer() and IsValid( target ) and target ~= self.HostBot then
		local ishost = false -- v == Entity(1)
		hates = ( target:Team() ~= self.HostBot:Team() and not ishost ) or cvars.Bool( "xdbot_huntplayers", false )
	end
	
	return not hates
end



function ENT:EnemyHandle()
	-- Clear if doesn't exist anymore or dead
	if not ( IsValid( self.CurrentEnemy ) and self.CurrentEnemy:Health() > 0 and self.CurrentEnemy ~= self.HostBot ) then
		self:ClearEnemyTarget()
	end

	-- Find closest visible one if we don't see
	if self.SeeEnemy == 0 or not IsValid( self.CurrentEnemy ) then
		local ent, dist = nil, 999999
		local getpos = self.HostBot:GetPos()

		for k, v in pairs( ents.FindInPVS( self.HostBot ) ) do
			
			if IsValid( v ) and v ~= self and v ~= self.HostBot and not self:IsTargetFriendly( v ) then
				local curdist = v:GetPos():Distance( getpos )
				if self:CanSeeEntity( v ) and curdist < dist and v:Health() > 0 then
					ent = v
					dist = curdist
				end
			end
			
		end

		if IsValid( ent ) then
			self.CurrentEnemy = ent
			self.EnemySeenLastTime = CurTime()
		end
	end
	
	--@TODO remove
	-- Update status and clean if we don't see it for too long
	local lookupentity = self.CurrentEnemy or self.FollowTarget
	if lookupentity then
		self.SeeEnemy = self:CanSeeTargetPart( lookupentity )
		if self.SeeEnemy == 0 then
			if CurTime() > ( self.EnemySeenLastTime + self.EnemySeenInterval ) then self:ClearEnemyTarget() end
			self.KeyAttack1 = false
		else
			self.EnemySeenLastTime = CurTime()
			local tr = self.HostBot:GetEyeTrace()
			self.KeyAttack1 = ( tr.Entity and tr.Entity == self.CurrentEnemy )
		end
	else
		self.KeyAttack1 = false
	end

end



function ENT:EntityFaceBack( ent )
	local angle = self.HostBot:GetAngles().y -ent:GetAngles().y
	if angle < -180 then angle = 360 + angle end
	if angle <= 90 and angle >= -90 then return true end
	return false
end



function ENT:CanSeeEntity( ent )
	--if not self:EntityFaceBack( ent ) then return false end -- @TODO: bugged
	return IsValid( ent ) and ( self.HostBot:Visible( ent ) or self.HostBot:VisibleVec( ent:GetPos() ) )
end



function ENT:CanSeeTargetPart( ent )
	-- @TODO:L VisibleVec. Valve even this couldn't handle
	if self:CanSeeEntity( ent ) then
		if ent:IsNPC() or ent:IsPlayer() then
			if self.HostBot:VisibleVec( ent:HeadTarget( self.HostBot:GetShootPos() ) ) then
				return 1
			elseif self.HostBot:VisibleVec( ent:GetPos() + ent:OBBCenter() ) then
				return 2
			else
				return 3
			end
		else
			return 3
		end
	else
		return 0
	end
end



function ENT:CanPickupEntity( ent )
	local canpickup = false
	if ent:IsWeapon() then
		-- The weapon is owned or being carried by someone else, ignore it
		if IsValid( ent:GetOwner() ) then return false end
		canpickup = hook.Run( "PlayerCanPickupWeapon", self.HostBot, ent ) or canpickup
	else
		canpickup = hook.Run( "PlayerCanPickupItem", self.HostBot, ent ) or canpickup
	end
	-- @TODO: return false if it's too high from ground
	return canpickup
end



function ENT:HandleGoalAim()
	-- @TODO: priority:
	-- Enemy, collect item, followtarget
	local lookuptarget = self.CurrentEnemy or self.FollowTarget
	if IsValid( lookuptarget ) and self.SeeEnemy > 0 then
		local enemy = lookuptarget
		if self.SeeEnemy == 1 then self.GoalAim = enemy:HeadTarget( self.HostBot:GetShootPos() )
		elseif self.SeeEnemy == 2 then self.GoalAim = enemy:GetPos() + enemy:OBBCenter()
		else self.GoalAim = enemy:GetPos() end
	elseif self.State == "findmedkit" or self.State == "collect" then
		if IsValid( self.CollectTarget ) then
			if self:CanSeeEntity( self.CollectTarget ) then
				self.GoalAim = self.CollectTarget:GetPos()
			else
				self.GoalAim = nil
			end
		end
	else
		self.GoalAim = nil
	end
end



function ENT:SwitchToBestWeapon()
	local weps = self.HostBot:GetWeapons()
	local weapprefs = list.Get( "XDBot_Weapprefs" )

	local curweap = self.HostBot:GetActiveWeapon():GetClass()
	local slowdown = weapprefs[ curweap ] and weapprefs[ curweap ].MovementSlowdown or 1
	local notusable = XDBOT_GLOBALS.WeapType_None
	local hostbot = self.HostBot
	local maxdamage = weapprefs[ curweap ] and ( weapprefs[ curweap ].Prim_damage * math.floor( 1 / weapprefs[ curweap ].Prim_rate + 1) ) or 0

	if IsValid( self.CurrentEnemy ) then
		-- @TODO: ideas
		-- switch to best one. Firstly we check weapons for proper distances. If target is farther,
		-- then pick one with biggest distance. Then we sort weapons with best effective damaging.
		-- effectivedmg = dmg * math.floor( 1/rate + 1 )
		-- Skip weapon if we don't have ammo
		local realdist = hostbot:GetPos():DistToSqr( self.CurrentEnemy:GetPos() )
		local maxdist = 0
		for k, v in pairs( weps ) do
			if weapprefs[ v:GetClass() ] then
				local pref = weapprefs[ v:GetClass() ]
				local useable = pref.Prim_type ~= notusable
				local idontwantthis = pref.Prim_type == XDBOT_GLOBALS.WeapType_Projectile
				local curdmg = pref.Prim_damage * math.floor( 1 / pref.Prim_rate + 1 )
				if not idontwantthis and curdmg > maxdamage and useable and v:HasAmmo() and realdist < ( pref.Prim_range * pref.Prim_range ) then
					curweap = v:GetClass()
					maxdamage = curdmg
				end
			end
		end
	else
		-- switch to one which has biggest MovementSlowdown (i.e. to one with which we move as fast as possible)
		-- or not if we are already comfortable with current holding weapon
		for k, v in pairs( weps ) do
			if weapprefs[ v:GetClass() ] then
				local pref = weapprefs[ v:GetClass() ]
				--local useable = not ( pref.Prim_type == notusable and pref.Sec_type == notusable )
				local useable = pref.Prim_type ~= notusable
				if not pref.MovementSlowdown then
					print("WARNING!",weapprefs[ v:GetClass() ], " has no pref.MovementSlowdown!!!")
				end
				if pref.MovementSlowdown and pref.MovementSlowdown > slowdown and useable then curweap = v:GetClass() end
			end
		end
	end

	-- @TODO: check if weapon is changed.
	self.HostBot:SelectWeapon( curweap )
end



function ENT:PlayerRespawn()
	--stub
end



function ENT:DeathThink()
	if self.HostBot:Alive() then
		print( self, "ENT:DeathThink()", "HostBot is actually alive. Why the hell you call me???" )
		return
	end
	self.FollowTarget = nil
	self.CollectTarget = nil
	self.UseTarget = nil
	self.State = "none"

	self:ClearEnemyTarget()

	self.GoalMove = nil
	self.TargetMove = nil
	self:InvalidatePath()
	self:TryToRespawn()
end



function ENT:CheckHostBot()
	if not ( self.HostBot and IsValid(self.HostBot) ) then
		print(self, "ENT:CheckHostBot()", "failed! Killing controller.")
		self:Remove()
	end
end



function ENT:FindAndSortEntities( options )

	options = options or {}

	options.maxdist = options.maxdist or 0 -- If lower or equal to zero, find everywhere
	options.type = options.type or "near" -- How to sort: "near", "far", "valuable" and "nosort" --@TODO: "random"?
	options.entclasses = options.entclasses or {} -- Search these entites
	options.entities = options.entities or {} -- We can also provide already found entities
	options.alive = options.alive or false -- Ignore dead targets
	options.friendly = options.friendly or false -- Should it be friendly

	local hostbot = self.HostBot
	local currentpos = hostbot:GetPos()

	if not ( options.entclasses or options.entities ) then
		print( self, "ENT:FindAndSortEntities()", "none of entities or classes to search provided" )
		return nil
	end

	--@TODO: implement tbl.type == "valuable". It's currently replaced by "near"
	if options.type == "valuable" then options.type = "near" end

	local entities = {}

	if options.entities then table.Merge( entities, options.entities ) end

	if options.entclasses then
		for i = 1, #options.entclasses do
			local foundbyclass = ents.FindByClass( options.entclasses[i] )
			table.Merge( entities, foundbyclass )
		end
	end

	if #entities < 1 then return nil end

	local found = {}

	for i = 1, #entities do

		local entitytbl = {}
		entitytbl.entity = entities[i]
		entitytbl.classname = entities[i]:GetClass()
		entitytbl.pos = entities[i]:GetPos()

		entitytbl.dist = currentpos:Distance( entitytbl.pos )

		-- If it's far from maxdist, then skip this entity
		if ( options.maxdist > 0 ) and ( entitytbl.dist > options.maxdist ) then continue end
		
		if options.alive and ( entitytbl.entity:Health() <= 0 ) then continue end
		
		if options.friendly and ( not self:IsTargetFriendly( entitytbl.entity ) ) then continue end

		-- @TODO: if valuable then import weapons preferences

		table.insert( found, entitytbl )

	end

	-- If there's only one entity, or no need to sort, return it now.
	if ( #found == 1 ) or ( options.type == "nosort" ) then return found end

	-------if options.type == "random" then end

	-- Now sort it
	if options.type == "near" then
		table.SortByMember( found, "dist", true )
	end

	if options.type == "far" then
		table.SortByMember( found, "dist", false )
	end

	-- @TODO: valuable
	-- if options.type == "valuable" then
	-- 	table.SortByMember( found, "dist", true )
	-- end

	return found
end



function ENT:ClearCollectState()
	self.State = "none"
	self.CollectTarget = nil
	self.GoalMove = nil
	self:ClearStuckStatus()
end



function ENT:ClearEnemyTarget()
	self.CurrentEnemy = nil
	self.SeeEnemy = 0
	self.EnemySeenLastTime = CurTime()
	self.EnemySeenLastPos = nil
end



function ENT:CheckForHealth()

	if self.HostBot:Health() < ( self.HostBot:GetMaxHealth() * 0.5 ) then
		local medkit = self:FindMedkit()
		if medkit then
			if self.State == "findmedkit" then
				-- Update wanted entity and it's pos, since it's closer
				self.CollectTarget = medkit.entity
			else
				self.State = "findmedkit"
				self.CollectTarget = medkit.entity
			end
		else -- if medkit
			if self.State == "findmedkit" then
				self:ClearCollectState()
			end
		end -- if medkit
	else
		if self.State == "findmedkit" then self:ClearCollectState() end
	end

	if self.State == "findmedkit" and not IsValid( self.CollectTarget ) then
		self:ClearCollectState()
	end

end



function ENT:FindMedkit()

	local options = {}
	options.entclasses = { "item_healthkit", "item_healthvial" }
	local medkits = self:FindAndSortEntities( options )
	if medkits then
		return medkits[1]
	end
	return nil

end



function ENT:FindPlayerToFollow()
	local options = {}
	--options.entclasses = { "player" }
	options.entities = player.GetHumans() -- not bots
	options.alive = true
	options.friendly = true
	
	local ply = self:FindAndSortEntities( options )
	if ply and ply[1] and IsValid( ply[1].entity ) then
		self.FollowTarget = ply[1].entity
	else
		self.FollowTarget = nil
	end
end



function ENT:FindGoodies( itemtbl, radius )

	local goodiestbl = {
		[ "item_ammo_357" ] = true,
		[ "item_ammo_357 large" ] = true,
		[ "item_ammo_ar2" ] = true,
		[ "item_ammo_ar2 altfire" ] = true,
		[ "item_ammo_ar2 large" ] = true,
		[ "item_ammo_crate" ] = true,
		[ "item_ammo_crossbow" ] = true,
		[ "item_ammo_pistol" ] = true,
		[ "item_ammo_pistol large" ] = true,
		[ "item_ammo_smg1" ] = true,
		[ "item_ammo_smg1 grenade" ] = true,
		[ "item_ammo_smg1 large" ] = true,
		[ "item_box_buckshot" ] = true,
		[ "item_rpg_round" ] = true
	}

	itemtbl = itemtbl or goodiestbl

	if self.HostBot:Health() < self.HostBot:GetMaxHealth() then
		itemtbl[ "item_healthkit" ] = true
		itemtbl[ "item_healthvial" ] = true
	end

	if self.HostBot:Armor() < 100 then
		itemtbl[ "item_battery" ] = true
	end

	radius = radius or 4096

	local options = {}
	options.entities = {}
	options.maxdist = radius

	local weapprefs = list.Get( "XDBot_Weapprefs" )

	for k, v in pairs( ents.FindInSphere( self.HostBot:GetPos(), radius ) ) do

		local class = v:GetClass()

		local useable = false
		if weapprefs[ class ] then
			useable = weapprefs[ class ].Prim_type ~= XDBOT_GLOBALS.WeapType_None
		end

		if  itemtbl[ class ] and useable and self:CanPickupEntity( v ) then
			table.insert( options.entities, v )
		end
	end

	local item = self:FindAndSortEntities( options )
	if item and #item > 0 and IsValid( item[1].entity ) then
		self.State = "collect"
		self.CollectTarget = item[1].entity
	end

end



local function getSignAndAbs( number )
	-- Returns '1'/'-1' and absolute value
	-- local absvalue = math.abs( number )
	-- return number / absvalue, absvalue
	local sign = 1
	if number < 0 then
		sign = 1
		number = number * (-1)
	end
	return sign, number
end

local function angleturn_specificaxisrates( currentAngle, targetAngle, ratep, ratey, rater )
	local retangle = Angle() -- angle to return
	retangle.pitch = math.ApproachAngle( currentAngle.pitch, targetAngle.pitch, ratep )
	retangle.yaw = math.ApproachAngle( currentAngle.yaw, targetAngle.yaw, ratey )
	--retangle.roll = math.ApproachAngle( currentAngle.roll, targetAngle.roll, rater )
	return retangle
end

local function angleturn( currentAngle, targetAngle, rate )
	return angleturn_specificaxisrates( currentAngle, targetAngle, rate, rate, rate )
end

function ENT:InterpolateViewAngle()
	-- Convert target pos into angle and store into target angle
	if self.GoalAim then
		self.TargetAim = self.GoalAim
	else
		self.TargetAim = self.TargetMove or self.HostBot:GetForward() * 128
	end
	local dir = ( self.TargetAim - self.HostBot:GetShootPos() ) + Vector( 0.001, 0.001, 0.001 ) -- without float parts vector:Angle() goes crazy!
	local angle = dir:Angle()
	angle:Normalize()
	self.CmdTargetAngle = angle

	-- now gradually interpolate current eye angle to target angle
	local amount = math.random() * 4 -- To simulate jittery
	local delta = angleturn( self.CmdCurAngle, self.CmdTargetAngle, amount )

	self.CmdCurAngle = delta
	--self.CmdCurAngle = self.CmdTargetAngle -- aimbot hax0r!

	self.HostBot:SetNWAngle( "xDBotAngles", self.CmdCurAngle )
end

local function AngleCopy( src, dest )
	dest.pitch = src.pitch
	dest.yaw = src.yaw
	dest.roll = src.roll
end

function ENT:HandleMovement()

	if not self.GoalMove then self.ShouldMove = false end

	if not self.ShouldMove or not self.TargetMove then
		self.CmdMove = Vector(0,0,0)
		return
	end

	local targetpos = self.StuckBypassPos or self.TargetMove
	if self.StuckBypassPos then print("self.StuckBypassPos",self.StuckBypassPos) end

	local curangle, targetangle = Angle(), Angle()
	AngleCopy( self.CmdCurAngle, curangle )
	AngleCopy( self.CmdTargetAngle, targetangle )
	curangle.p = 0
	targetangle.p = 0

	local dir, _ = WorldToLocal( targetpos, targetangle, self.HostBot:GetPos(), curangle )
	-- local dir2d = Vector( dir.x, dir.y, 0):GetNormalized() * 250
	-- local dirz = Vector( 0, 0, dir.z ):GetNormalized() * 250
	-- dir = dir2d + dirz
	dir = dir:GetNormalized() * 999999
	dir.y = dir.y * (-1)
	self.CmdMove = dir

	self.HostBot:SetNWVector( "xDBotMove", self.CmdMove )
end



function ENT:HandleKeys()
	local ongound = self.HostBot:IsOnGround()

	if self.ShouldMoveCrouch or self.KeyCrouch or not ongound then
		self.CmdButtons = bit.bor( self.CmdButtons, IN_DUCK )
	else
		self.CmdButtons = bit.band( self.CmdButtons, bit.bnot( IN_DUCK ) )
	end

	local alreadypressedjump = bit.band( self.CmdButtons, IN_JUMP ) > 0
	if ( self.ShouldMoveJump or self.keyJump ) and ongound and not alreadypressedjump then
		self.CmdButtons = bit.bor( self.CmdButtons, IN_JUMP )
	else
		self.CmdButtons = bit.band( self.CmdButtons, bit.bnot( IN_JUMP ) )
	end

	if self.ShouldMoveForward then
		self.CmdButtons = bit.bor( self.CmdButtons, IN_FORWARD )
	else
		self.CmdButtons = bit.band( self.CmdButtons, bit.bnot( IN_FORWARD ) )
	end

	if self.KeyUse then
		self.CmdButtons = bit.bor( self.CmdButtons, IN_USE )
	else
		self.CmdButtons = bit.band( self.CmdButtons, bit.bnot( IN_USE ) )
	end

	if self.KeySpeed then
		self.CmdButtons = bit.bor( self.CmdButtons, IN_SPEED )
	else
		self.CmdButtons = bit.band( self.CmdButtons, bit.bnot( IN_SPEED ) )
	end

	if self.KeyAttack1 then
		self.CmdButtons = bit.bor( self.CmdButtons, IN_ATTACK )
	else
		self.CmdButtons = bit.band( self.CmdButtons, bit.bnot( IN_ATTACK ) )
	end

	if self.KeyAttack2 then
		self.CmdButtons = bit.bor( self.CmdButtons, IN_ATTACK2 )
	else
		self.CmdButtons = bit.band( self.CmdButtons, bit.bnot( IN_ATTACK2 ) )
	end

	self.HostBot:SetNWInt( "xDBotButtons", self.CmdButtons )

end


--[[
function ENT:HandlePlayermodelOnRespawn()

	if not IsValid(self.HostBot) then
		print(self, "HandlePlayermodelOnRespawn", "Invalid self.HostBot!" )
		return
	end

	-- Don't do anything if it's player
	if self.HostBot:IsPlayer() and not self.HostBot:IsBot() then return end

	local cl_playermodel = self.Personatable.Model
	local modelname = player_manager.TranslatePlayerModel( cl_playermodel )
	util.PrecacheModel( modelname )
	self.HostBot:SetModel( modelname )

	self.HostBot:SetPlayerColor( Vector( self.Personatable.Playercolor ) )

	local col = Vector( self.Personatable.Weaponcolor )
	if col:Length() == 0 then
		col = Vector( 0.001, 0.001, 0.001 )
	end
	self.HostBot:SetWeaponColor( col )

	local skin = self.Personatable.Skin or 0
	self.HostBot:SetSkin( skin )

	local groups = self.Personatable.Bodygroups
	if ( groups == nil ) then groups = "" end
	local groups = string.Explode( " ", groups )
	for k = 0, self.HostBot:GetNumBodyGroups() - 1 do --@TODO: look on it deeper....
		self.HostBot:SetBodygroup( k, tonumber( groups[ k + 1 ] ) or 0 )
	end

	return true

end
]]--

function ENT:TryToRespawn()
	if ( self.HostBot.NextSpawnTime and self.HostBot.NextSpawnTime <= CurTime() ) then
		self.HostBot:Spawn()
	end
end



function ENT:UpdateTransmitState()
	-- Clients will never know about controller existing and will never guess if it's bot, muahahhaha (they will)
	return TRANSMIT_NEVER
end



function ENT:OnInjured( damage )
	damage:ScaleDamage(0.00)
	return false
end



function ENT:ReceivedPlyInput()
	print(self, "ReceivedPlyInput", "Caught player pressing button. Killing controller and give control back to player.")
	self:Remove()
end



function ENT:GotoLookpos( pos )
	-- @TODO: stub
	print( self, "ENT:GotoLookpos", "received!", pos )
	self:ChangeGoalMove( pos )
end



function ENT:OnRemove()
	self.TargetAim = nil
	self.TargetMove = nil

	self.GoalAim = nil
	self.GoalMove = nil

	self.ShouldMove = false
	self.ShouldMoveCrouch = false
	self.ShouldMoveJump = false

	self.CmdButtons = nil

	if self.HostBot and IsValid( self.HostBot ) then
		self.HostBot.ControllerEnt = nil
		self.HostBot:SetNWBool( "isXDBot", false )
	end
	print(self, "terminated.")
end
