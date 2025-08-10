local metaPlayer = FindMetaTable( "Player" )
local fLastFingerUpdate = 0 
local fLastFootUpdate = 0

function metaPlayer:IM_CreateBullet( vPos, aAngle, sModel, sClassname, iAmmoType )
	local eBullet = ents.Create( "investigation_bullet" )
	eBullet:SetPos( vPos )
	eBullet:SetAngles( aAngle )
	eBullet:SetWeaponModel( sModel )
	eBullet:SetWeaponName( sClassname )
	eBullet:SetWeaponAmmo( iAmmoType )
	eBullet:SetMurder( self )
	eBullet:Spawn()

	
	timer.Simple( InvestigationMod:GetConfig( "Time_RagdollRemoved" ), function()
		if IsValid( eBullet ) then
			eBullet:Remove()
		end
	end )

	return eBullet
end

local DeathCauses
function metaPlayer:IM_DeathBody( tDamageInfos, pCriminal, vPos, sModel )
        DeathCauses = DeathCauses or {
		[ DMG_GENERIC ] = InvestigationMod:L( "Wounded" ),
		[ DMG_CRUSH ] = InvestigationMod:L( "Crushed" ),
		[ DMG_BULLET ] = InvestigationMod:L( "Shot" ),
		[ DMG_BURN ] = InvestigationMod:L( "Burned" ),
		[ DMG_VEHICLE ] = InvestigationMod:L( "Vehicle hit" ),
		[ DMG_FALL ] = InvestigationMod:L( "Fall damage" ),
		[ DMG_BLAST ] = InvestigationMod:L( "Explosion damage" ),
		[ DMG_NEVERGIB ] = InvestigationMod:L( "Crossbow" ),
		[ DMG_NERVEGAS ] = InvestigationMod:L( "Neurotoxin" ),
		[ DMG_POISON ] = InvestigationMod:L( "Poison" ),
		[ DMG_RADIATION ] = InvestigationMod:L( "Radiation" ),
		[ DMG_ACID ] = InvestigationMod:L( "Acid" ),
        }

        -- tDamageInfos can be either a CTakeDamageInfo object or a damage type number
        local iDamageType = 0
        if isnumber( tDamageInfos ) then
                iDamageType = tDamageInfos
        elseif tDamageInfos and tDamageInfos.GetDamageType then
                local ok, dmgType = pcall( tDamageInfos.GetDamageType, tDamageInfos )
                if ok and dmgType then
                        iDamageType = dmgType
                end
        end

        if ( ConfigurationMedicMod or CH_AdvMedic ) and IsValid( self.DeathRagdoll ) then
                -- Medic mod body, don't spawn the ragdoll until he really die
                self.IM_tDamageInfos = {}
                self.IM_tDamageInfos.DamageType = iDamageType
                self.IM_tDamageInfos.Pos = self:GetPos()
                self.IM_tDamageInfos.Model = self:GetModel()
                self.IM_tDamageInfos.Criminal = pCriminal
                return
        end

	local eCube = ents.Create( "investigation_body" )
	eCube:SetPos( vPos or self:GetPos() )
	eCube:SetVictimName( self:Name() )
	eCube:SetVictimJob( team.GetName( self:Team() ) )
	eCube:SetDeathTime( os.time() )
	eCube:Spawn()
	eCube:SetNoDraw( true )
	eCube:SetCollisionGroup( COLLISION_GROUP_WORLD )

        local DeathType
        for iDmgType, sDmg in pairs( DeathCauses ) do
                if bit.band( iDamageType, iDmgType ) ~= 0 then
                        DeathType = ( DeathType and DeathType .. ", " or "" ) .. sDmg
                end
        end
        eCube:SetDamageType( DeathType or "" )

	-- create the ragdoll
    local eRagdoll = ents.Create("prop_ragdoll")
    eRagdoll:SetPos( eCube:GetPos() )
    eRagdoll:SetAngles( self:GetAngles() )
    eRagdoll:SetModel( sModel or self:GetModel() )
    eRagdoll:SetParent( eCube )
    eRagdoll:SetOwner( eCube )
	eRagdoll:Spawn()
    eRagdoll:Activate()
	eRagdoll:AddEFlags( EFL_IN_SKYBOX )
	eRagdoll:DeleteOnRemove( eCube )
	if not InvestigationMod.Configuration.ShouldBodyCollide then
		eRagdoll:SetCollisionGroup( COLLISION_GROUP_WORLD )
	end

	timer.Simple( InvestigationMod:GetConfig( "Time_RagdollRemoved" ), function()
		if IsValid( eCube ) then
			eCube:Remove()
		end
	end )

	if IsValid( InvestigationMod.DeathBodies[ self ] ) then InvestigationMod.DeathBodies[ self ]:Remove() end
	InvestigationMod.DeathBodies[ self ] = eCube

	if not ( ConfigurationMedicMod or CH_AdvMedic ) then
		self:Spectate( OBS_MODE_CHASE )
		self:SpectateEntity( eRagdoll )
	end

	eCube:SetBody( eRagdoll )
	if IsValid( pCriminal ) then
		eCube:SetCriminal( pCriminal )
	end

    constraint.Weld(eRagdoll, eCube, 0, 0, 0, false)

    -- Remove ragdoll ent
    timer.Simple(0.01, function()
        if IsValid( self:GetRagdollEntity() ) then
            self:GetRagdollEntity():Remove()
        end
    end)

    hook.Run( "InvestigationMod:OnBodySpawned", self, eCube, eRagdoll )
end

--[[
	Fingerprints functions
]]
function metaPlayer:IM_RegisterDoorFinger( eDoor )
	if not IsValid( eDoor ) then return end

	local iDoor = eDoor:EntIndex()
	local tTrace = self:GetEyeTrace()
	local vPos = eDoor:WorldToLocal( tTrace.HitPos )
	local aAngle = eDoor:WorldToLocalAngles( tTrace.HitNormal:Angle() )

	fLastFingerUpdate = CurTime()

	InvestigationMod.DoorFingerprint[ self:SteamID() ] = InvestigationMod.DoorFingerprint[ self:SteamID() ] or {}
	InvestigationMod.DoorFingerprint[ self:SteamID()  ][ iDoor ] = InvestigationMod.DoorFingerprint[ self:SteamID() ][ iDoor ] or {}
	-- Only one per door so if he left a new fingerprint, remove the old one
	InvestigationMod.DoorFingerprint[ self:SteamID() ][ iDoor ] = { pos = vPos, time = CurTime(), realAngle = aAngle }
end

function InvestigationMod.RemoveDoorFinger( iDoor, sPlayer )
	if not iDoor or not sPlayer then return end
	if not InvestigationMod.DoorFingerprint or not InvestigationMod.DoorFingerprint[ sPlayer ] then return end

	InvestigationMod.DoorFingerprint[ sPlayer ][ iDoor ] = nil
end

function metaPlayer:IM_SendDoorFinger()
	-- Prevent to send the net if nothing has changed
	if self.IM_LastDoorFingersUpdate and self.IM_LastDoorFingersUpdate > fLastFingerUpdate then return end

	self.IM_LastDoorFingersUpdate = CurTime()

	-- Remove useless values
	for pPlayer, iDoor in pairs( InvestigationMod.DoorFingerprint or {} ) do
		if not IsValid( player.GetBySteamID( pPlayer or 0 ) ) then InvestigationMod.DoorFingerprint[ pPlayer ] = nil continue end
		for iDoor, tDoor in pairs( iDoor ) do
			if not tDoor.time or tDoor.time + InvestigationMod:GetConfig( "Time_ClueRemoved" ) < CurTime() then
				InvestigationMod.DoorFingerprint[ pPlayer ][ iDoor ] = nil
			end
		end
	end

	local jsonTable = util.TableToJSON( InvestigationMod.DoorFingerprint )
	local compressedJson = util.Compress( jsonTable )

	net.Start( "InvestigationMod.SendDoorPrints" )
		net.WriteUInt( compressedJson:len(), 32 )
		net.WriteData( compressedJson, compressedJson:len() )
	net.Send( self )
end

function metaPlayer:IM_GetDoorFinger()
	return InvestigationMod.DoorFingerprint[ self:SteamID() ] or {}
end

function metaPlayer:IM_ShouldRegisterDoorFinger( bShould )
	if type( bShould ) == "boolean" then
		self.ShouldRegisterDoorFinger = bShould
	end

	return self.ShouldRegisterDoorFinger
end

--[[
	Footsteps functions
]]
function metaPlayer:IM_RegisterFootsteps( iFoot, vPos )
	fLastFootUpdate = CurTime()

	InvestigationMod.FootSteps[ self:SteamID() ] = InvestigationMod.FootSteps[ self:SteamID() ] or {}
	InvestigationMod.FootSteps[ self:SteamID()  ][ iFoot ] = InvestigationMod.FootSteps[ self:SteamID() ][ iFoot ] or {}
	table.insert( InvestigationMod.FootSteps[ self:SteamID() ][ iFoot ], { angle = self:GetAngles(), pos = vPos, time = CurTime() } )
end

function metaPlayer:IM_SendFootprints()
	-- Prevent to send the net if nothing has changed
	if self.IM_LastFootprintsUpdate and self.IM_LastFootprintsUpdate > fLastFootUpdate then return end

	self.IM_LastFootprintsUpdate = CurTime()

	-- Remove useless values
	for pPlayer, tFoots in pairs( InvestigationMod.FootSteps ) do
		if not IsValid( player.GetBySteamID( pPlayer or 0 ) ) then InvestigationMod.FootSteps[ pPlayer ] = nil continue end
		for iFoot, tFoot in pairs( tFoots ) do
			for _, tFootInfo in pairs( tFoot ) do
				if not tFootInfo.time or tFootInfo.time + InvestigationMod:GetConfig( "Time_ClueRemoved" ) < CurTime() then
					InvestigationMod.FootSteps[ pPlayer ][ iFoot ][ _ ] = nil
				end
			end
		end
	end

	local jsonTable = util.TableToJSON( InvestigationMod.FootSteps )
	local compressedJson = util.Compress( jsonTable )

	net.Start( "InvestigationMod.SendFootPrints" )
		net.WriteUInt( compressedJson:len(), 32 )
		net.WriteData( compressedJson, compressedJson:len() )
	net.Send( self )

end

function metaPlayer:IM_GetFootsteps()
	return InvestigationMod.FootSteps[ self:SteamID() ] or {}
end

function metaPlayer:IM_ShouldRegisterFootsteps( bShould )
	if type( bShould ) == "boolean" then
		self.ShouldRegisterFootsteps = bShould
	end

	return self.ShouldRegisterFootsteps
end
