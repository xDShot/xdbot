AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"

ENT.PrintName = "Collision test"
ENT.Author = "xDShot"
ENT.Information = "This is to test collide detection for players"
ENT.Category = "Other"

ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:Initialize()

	self.BypassDir = nil

	self.Collisionhulls = {
		Base = {}, -- Firstly it is checked
		RF = {}, -- Right front
		LF = {}, -- Left front
		Jump = {}, -- Above if needed to crouch
		Crouch = {}  -- Check in front if we need to crouch. Between step and crouch height
	}

    if CLIENT then return end
	self:SetModel( "models/xdbot/playerstart_collisiontest.mdl" )
	self:PhysicsInit( SOLID_BBOX )

end



function ENT:Think()
	self:DetectCollision()
end



-- hull + tracelines method:
-- |    |
-- |_[]_|
function ENT:DetectCollision()
	local stepheight = 18 -- self.HostBot:GetStepSize()
	local ent = self -- self.HostBot

	local standmins, standmaxs = ent:OBBMins(), ent:OBBMaxs() -- ent:GetHull()
	local duckmins, duckmaxs = Vector(-16,-16,0), Vector(16,16,36) -- ent:GetHullDuck()
	local mins, maxs = duckmins, duckmaxs
	-- Just in case if I messed up with vector ordering again
	OrderVectors( mins, maxs )
	local startpos = ent:GetPos()
	local mask = MASK_PLAYERSOLID
	local collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
	local filter = { ent, self } -- Ignore HostBot and self
	local basethick = 4
	local distx = maxs.x
	local disty = maxs.y

	-- Clear Collisionhulls and BypassDir vector
	self.Collisionhulls.Base = {}
	self.Collisionhulls.RF = {} -- right forward
	self.Collisionhulls.LF = {} -- left forward
	self.BypassDir = nil

	-- For each tracesesults we need to store some info that we used for trace initialization
	local trstartpos = startpos
	local trendpos = startpos
	local trmaxs = maxs+Vector( basethick, basethick, 0 )
	local trmins = mins+Vector( -basethick, -basethick, stepheight )
	-- We don't need exact lenght anyway
	local lensqr = 0 -- Base has zero length

	self.Collisionhulls.Base = util.TraceHull( {
		start = trstartpos,
		endpos = trendpos,
		maxs = trmaxs,
		mins = trmins,
		filter = filter,
        mask = mask,
        collisiongroup = collisiongroup
	} )
	self.Collisionhulls.Base.endpos = trendpos
	self.Collisionhulls.Base.lensqr = lensqr
	self.Collisionhulls.Base.maxs = trmaxs
	self.Collisionhulls.Base.mins = trmins

	-- Trace rest if we collide with something that blocks movement
	if self.Collisionhulls.Base.Hit then
		local dist = distx + basethick
		local right = ent:GetRight() * dist + Vector( 0, 0, stepheight )
		local forward = ent:GetForward() * dist + Vector( 0, 0, stepheight )

		trstartpos = startpos + right
		trendpos = trstartpos + forward

		self.Collisionhulls.RF = util.TraceLine( {
		start = trstartpos,
		endpos = trendpos,
		filter = filter,
        mask = mask,
        collisiongroup = collisiongroup
		} )

		trstartpos = startpos - right
		trendpos = trstartpos + forward

		self.Collisionhulls.LF = util.TraceLine( {
		start = trstartpos,
		endpos = trendpos,
		filter = filter,
        mask = mask,
        collisiongroup = collisiongroup
		} )

		if self.Collisionhulls.RF.Hit and self.Collisionhulls.LF.Hit then
			self.BypassDir = 1 -- go left
			if self.Collisionhulls.LF.Fraction < self.Collisionhulls.RF.Fraction then self.BypassDir = 2 end -- go right
		end
	end
end



-- OBSOLETE. 5 hulls method
--[[
function ENT:DetectCollision()

	local stepheight = 18 -- self.HostBot:GetStepSize()
	local ent = self -- self.HostBot

	local standmins, standmaxs = ent:OBBMins(), ent:OBBMaxs() -- ent:GetHull()
	local duckmins, duckmaxs = Vector(-16,-16,0), Vector(16,16,36) -- ent:GetHullDuck()
	local mins, maxs = duckmins, duckmaxs
	-- Just in case if I messed up with vector ordering again
	OrderVectors( mins, maxs )
	local startpos = ent:GetPos()
	local mask = MASK_PLAYERSOLID
	local collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
	local filter = { ent, self } -- Ignore HostBot and self
	local basethick = 16
	local distx = maxs.x
	local disty = maxs.y

	-- Clear Collisionhulls and BypassDir vector
	self.Collisionhulls.Base = {}
	self.Collisionhulls.NW = {}
	self.Collisionhulls.NE = {}
	self.Collisionhulls.SW = {}
	self.Collisionhulls.SE = {}
	self.BypassDir = nil

	-- For each tracesesults we need to store some info that we used for trace initialization
	local trstartpos = startpos
	local trendpos = startpos
	local trmaxs = maxs+Vector( basethick, basethick, 0 )
	local trmins = mins+Vector( -basethick, -basethick, stepheight )
	-- We don't need exact lenght anyway
	local lensqr = 0 -- Base has zero length

	self.Collisionhulls.Base = util.TraceHull( {
		start = trstartpos,
		endpos = trendpos,
		maxs = trmaxs,
		mins = trmins,
		filter = filter,
        mask = mask,
        collisiongroup = collisiongroup
	} )
	self.Collisionhulls.Base.endpos = trendpos
	self.Collisionhulls.Base.lensqr = lensqr
	self.Collisionhulls.Base.maxs = trmaxs
	self.Collisionhulls.Base.mins = trmins

	-- Trace rest if we collide with something that blocks movement
	if self.Collisionhulls.Base.HitWorld then

		self.BypassDir = Vector( 0.01, 0.01, 0.01 )

		trmins = Vector(-distx/2,-disty/2,stepheight)
		trmaxs = Vector(distx/2,disty/2,maxs.z)

		trstartpos = startpos + Vector( -distx/2, disty/2, 0 )
		trendpos = trstartpos + Vector( -distx, disty, 0 )
		lensqr = ( trendpos - trstartpos ):LengthSqr()

		self.Collisionhulls.NW = util.TraceHull( {
			start = trstartpos,
			endpos = trendpos,
			maxs = trmaxs,
			mins = trmins,
			filter = filter,
        	mask = mask,
        	collisiongroup = collisiongroup
		} )
		self.Collisionhulls.NW.endpos = trendpos
		self.Collisionhulls.NW.lensqr = lensqr
		self.Collisionhulls.NW.maxs = trmaxs
		self.Collisionhulls.NW.mins = trmins
		if self.Collisionhulls.NW.Hit then
			local bypassdir = ( trstartpos - trendpos ):GetNormalized()
			local bypasslen = lensqr * ( 1 - self.Collisionhulls.NW.Fraction ) + 0.01
			self.BypassDir = self.BypassDir + bypassdir * bypasslen
		end

		trstartpos = startpos + Vector( distx/2, disty/2, 0 )
		trendpos = trstartpos + Vector( distx, disty, 0 )

		self.Collisionhulls.NE = util.TraceHull( {
			start = trstartpos,
			endpos = trendpos,
			maxs = maxs,
			mins = mins+Vector(0,0,stepheight),
			filter = filter,
        	mask = mask,
        	collisiongroup = collisiongroup
		} )
		self.Collisionhulls.NE.endpos = trendpos
		self.Collisionhulls.NE.lensqr = lensqr
		self.Collisionhulls.NE.maxs = trmaxs
		self.Collisionhulls.NE.mins = trmins
		if self.Collisionhulls.NE.Hit then
			local bypassdir = ( trstartpos - trendpos ):GetNormalized()
			local bypasslen = lensqr * ( 1 - self.Collisionhulls.NE.Fraction ) + 0.01
			self.BypassDir = self.BypassDir + bypassdir * bypasslen
		end

		trstartpos = startpos + Vector( -distx/2, -disty/2, 0 )
		trendpos = trstartpos + Vector( -distx, -disty, 0 )

		self.Collisionhulls.SW = util.TraceHull( {
			start = trstartpos,
			endpos = trendpos,
			maxs = maxs,
			mins = mins+Vector(0,0,stepheight),
			filter = filter,
        	mask = mask,
        	collisiongroup = collisiongroup
		} )
		self.Collisionhulls.SW.endpos = trendpos
		self.Collisionhulls.SW.lensqr = lensqr
		self.Collisionhulls.SW.maxs = trmaxs
		self.Collisionhulls.SW.mins = trmins
		if self.Collisionhulls.SW.Hit then
			local bypassdir = ( trstartpos - trendpos ):GetNormalized()
			local bypasslen = lensqr * ( 1 - self.Collisionhulls.SW.Fraction ) + 0.01
			self.BypassDir = self.BypassDir + bypassdir * bypasslen
		end

		trstartpos = startpos + Vector( distx/2, -disty/2, 0 )
		trendpos = trstartpos + Vector( distx, -disty, 0 )

		self.Collisionhulls.SE = util.TraceHull( {
			start = trstartpos,
			endpos = trendpos,
			maxs = maxs,
			mins = mins+Vector(0,0,stepheight),
			filter = filter,
        	mask = mask,
        	collisiongroup = collisiongroup
		} )
		self.Collisionhulls.SE.endpos = trendpos
		self.Collisionhulls.SE.lensqr = lensqr
		self.Collisionhulls.SE.maxs = trmaxs
		self.Collisionhulls.SE.mins = trmins
		if self.Collisionhulls.SE.Hit then
			local bypassdir = ( trstartpos - trendpos ):GetNormalized()
			local bypasslen = lensqr * ( 1 - self.Collisionhulls.SE.Fraction ) + 0.01
			self.BypassDir = self.BypassDir + bypassdir * bypasslen
		end
	else
		if self.Collisionhulls.Base.Entity and IsValid( self.Collisionhulls.Base.Entity ) then
			self.BypassDir = startpos - self.Collisionhulls.Base.Entity:GetPos()
			self.BypassDir.z = 0
			self.BypassDir = self.BypassDir:GetNormalized() * 256
		end
	end -- if self.Collisionhulls.Base.Hit then

end




function ENT:Draw()

    if not CLIENT then return end

    self:DrawModel()

	local ent = self -- self.HostBot

	local blue = Color( 2, 231, 212 )
	local red = Color( 244, 5, 45 )
	local violet = Color( 175, 5, 242 )

    -- --Player Hull
    render.DrawWireframeBox( ent:GetPos(), Angle( 0, 0, 0 ), ent:OBBMins(), ent:OBBMaxs(), color_white, true )
    -- -- Collision detection
    -- render.DrawWireframeBox( tr.HitPos, Angle( 0, 0, 0 ), mins, maxs, clr, true )

	-- render.DrawLine( startpos, tr.HitPos, color_white, true )

	if self.Collisionhulls.Base.HitWorld then
		local tr = self.Collisionhulls.NW or {}
		if tr then
			render.DrawWireframeBox( tr.HitPos, Angle( 0, 0, 0 ), tr.mins, tr.maxs, tr.Hit and red or blue, true )
		end
		tr = self.Collisionhulls.NE or {}
		if tr then
			render.DrawWireframeBox( tr.HitPos, Angle( 0, 0, 0 ), tr.mins, tr.maxs, tr.Hit and red or blue, true )
		end
		tr = self.Collisionhulls.SW or {}
		if tr then
			render.DrawWireframeBox( tr.HitPos, Angle( 0, 0, 0 ), tr.mins, tr.maxs, tr.Hit and red or blue, true )
		end
		tr = self.Collisionhulls.SE or {}
		if tr then
			render.DrawWireframeBox( tr.HitPos, Angle( 0, 0, 0 ), tr.mins, tr.maxs, tr.Hit and red or blue, true )
		end
	else
		local tr = self.Collisionhulls.Base or {}
		if tr.Entity then
			render.DrawWireframeBox( tr.HitPos, Angle( 0, 0, 0 ), tr.mins, tr.maxs, tr.Hit and red or blue, true )
		end
	end

	if self.BypassDir then
		print(self.BypassDir)
		render.DrawLine( ent:GetPos(), ent:GetPos() + self.BypassDir, violet, true )
	end

end
]]--