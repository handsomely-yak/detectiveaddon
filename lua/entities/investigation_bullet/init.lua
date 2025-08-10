AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()

	self:SetModel( "models/venatuss/bullet/bullet.mdl" )
	self:SetUseType( SIMPLE_USE )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
	end
	
end

function ENT:Pack( pCaller )
	if not InvestigationMod:IsAllowedToInvestigate( pCaller ) then return end

	hook.Run( "InvestigationMod:OnBulletTaken", pCaller )

	self:Remove()
end