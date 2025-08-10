AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()

	self:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )
	self:SetUseType( SIMPLE_USE )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
	end
	
end

function ENT:Burn()
	self:SetCriminal( NULL )
	self:SetVictimName( InvestigationMod:L( "UNKNOWN" ) )
	self:SetVictimJob( InvestigationMod:L( "UNKNOWN" ) )
	self:SetDeathTime( -1 )
	self:SetDamageType( InvestigationMod:L( "UNKNOWN" ) )

	if IsValid( self:GetBody() ) then
		self:GetBody():Ignite( 30 )
		timer.Simple( 30, function()
			if not IsValid( self ) or not IsValid( self:GetBody() ) then return end
			-- Set to burned body
			self:GetBody():SetModel( "models/player/charple.mdl" )
		end )
	end

	hook.Run( "InvestigationMod:OnBodyBurned", self )
end