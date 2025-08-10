InvestigationMod.FootSteps = {}
InvestigationMod.DoorFingerprint = {}
InvestigationMod.DeathBodies = {}

--[[
	Doing this for the AMM compatibility
]]
hook.Add( "DoPlayerDeath", "DoPlayerDeath.InvestigationMod", function( pVictim, pAttacker, cDamageInfos )
        pVictim.IM_DeathInfo = {
                Attacker = pAttacker,
                DamageType = cDamageInfos and cDamageInfos:GetDamageType() or 0,
                IsBullet = cDamageInfos and cDamageInfos:IsBulletDamage() or false,
                AmmoType = cDamageInfos and cDamageInfos:GetAmmoType() or 0
        }
end )


hook.Add( "PostPlayerDeath", "PostPlayerDeath.InvestigationMod", function( pVictim )
        if not pVictim.IM_DeathInfo then return end

        local pAttacker = pVictim.IM_DeathInfo.Attacker
        local iDamageType = pVictim.IM_DeathInfo.DamageType
        local bBullet = pVictim.IM_DeathInfo.IsBullet
        local iAmmoType = pVictim.IM_DeathInfo.AmmoType

        pVictim:IM_DeathBody( iDamageType, pAttacker )
        pVictim.IM_DeathInfo = nil

        if not IsValid( pAttacker ) or not pAttacker:IsPlayer() or pAttacker == pVictim then return end
        if bBullet then
                if not IsValid( pAttacker:GetActiveWeapon() ) or InvestigationMod.Configuration.DontDropBullet[ pAttacker:GetActiveWeapon():GetClass() ] then return end

                pAttacker:IM_CreateBullet( pVictim:GetPos(), pAttacker:GetAngles(), pAttacker:GetActiveWeapon():GetModel(), pAttacker:GetActiveWeapon():GetClass(), iAmmoType )
                pAttacker:IM_ShouldRegisterFootsteps( true )
                pAttacker:IM_ShouldRegisterDoorFinger( true )

                timer.Simple( InvestigationMod:GetConfig( "Time_RegisterPrints" ), function()
                        if IsValid( pAttacker ) then
                                pAttacker:IM_ShouldRegisterFootsteps( false )
                                pAttacker:IM_ShouldRegisterDoorFinger( false )
                        end
                end )
        end
end )

hook.Add( "DoPlayerDeath", "DoPlayerDeath.InvestigationMod", function( pVictim, pAttacker, cDamageInfos )
        pVictim.IM_DeathInfo = {
                Attacker = pAttacker,
                DamageType = cDamageInfos and cDamageInfos:GetDamageType() or 0,
                IsBullet = cDamageInfos and cDamageInfos:IsBulletDamage() or false,
                AmmoType = cDamageInfos and cDamageInfos:GetAmmoType() or 0
        }
end )


hook.Add( "PostPlayerDeath", "PostPlayerDeath.InvestigationMod", function( pVictim )
        if not pVictim.IM_DeathInfo then return end

        local pAttacker = pVictim.IM_DeathInfo.Attacker
        local iDamageType = pVictim.IM_DeathInfo.DamageType
        local bBullet = pVictim.IM_DeathInfo.IsBullet
        local iAmmoType = pVictim.IM_DeathInfo.AmmoType

        pVictim:IM_DeathBody( iDamageType, pAttacker )
        pVictim.IM_DeathInfo = nil

        if not IsValid( pAttacker ) or not pAttacker:IsPlayer() or pAttacker == pVictim then return end
        if bBullet then
                if not IsValid( pAttacker:GetActiveWeapon() ) or InvestigationMod.Configuration.DontDropBullet[ pAttacker:GetActiveWeapon():GetClass() ] then return end

                pAttacker:IM_CreateBullet( pVictim:GetPos(), pAttacker:GetAngles(), pAttacker:GetActiveWeapon():GetModel(), pAttacker:GetActiveWeapon():GetClass(), iAmmoType )
                pAttacker:IM_ShouldRegisterFootsteps( true )
                pAttacker:IM_ShouldRegisterDoorFinger( true )

                timer.Simple( InvestigationMod:GetConfig( "Time_RegisterPrints" ), function()
                        if IsValid( pAttacker ) then
                                pAttacker:IM_ShouldRegisterFootsteps( false )
                                pAttacker:IM_ShouldRegisterDoorFinger( false )
                        end
                end )
        end
end )

hook.Add( "PlayerFootstep", "PlayerFootstep.InvestigationMod", function( pPlayer, vPos, iFoot ) 
	if pPlayer:IM_ShouldRegisterFootsteps() then
		pPlayer:IM_RegisterFootsteps( iFoot, vPos )
	end
end )

local doorsList = {
	[ "func_door" ] = true,
	[ "func_door_rotating" ] = true,
	[ "prop_door_rotating" ] = true,
	[ "prop_dynamic" ] = true,
}
hook.Add( "PlayerUse", "PlayerUse.InvestigationMod", function( pPlayer, eEnt )
	if IsValid( eEnt ) and doorsList[ eEnt:GetClass() ] and pPlayer:IM_ShouldRegisterDoorFinger() then
		pPlayer:IM_RegisterDoorFinger( eEnt )
	end
end )


--[[
	Medic mod compatibility
]]
hook.Add( "PlayerSpawn", "MedicMod.InvestigationMod", function( pPlayer )
	if not ConfigurationMedicMod then return end

        timer.Simple( 0.2, function()
                if pPlayer.IM_tDamageInfos then
                        pPlayer:IM_DeathBody( pPlayer.IM_tDamageInfos.DamageType, pPlayer.IM_tDamageInfos.Criminal, pPlayer.IM_tDamageInfos.Pos, pPlayer.IM_tDamageInfos.Model )
                        pPlayer.IM_tDamageInfos = nil
                end
        end )
end )

hook.Add( "EntityRemoved", "MedicMod.InvestigationMod", function( eEntity )
	if IsValid( eEntity ) and isfunction( eEntity.IsDeathRagdoll ) and eEntity:IsDeathRagdoll() then 
		local pPlayer = eEntity:GetOwner()
                if IsValid( pPlayer ) and pPlayer.IM_tDamageInfos then
                        pPlayer.IM_tDamageInfos.Pos = eEntity:GetPos()
                end
	end
end )

hook.Add( "onPlayerRevived", "MedicMod.InvestigationMod", function( pPlayer )
	if not ConfigurationMedicMod then return end

	timer.Simple( 1, function()
		if IsValid( InvestigationMod.DeathBodies[ pPlayer ] ) then
			if IsValid( InvestigationMod.DeathBodies[ pPlayer ]:GetParent() ) then
				InvestigationMod.DeathBodies[ pPlayer ]:GetParent():Remove()
			end
			InvestigationMod.DeathBodies[ pPlayer ]:Remove()
		end
	end )
end )

--[[
	Crap head's medic mod compatibility
]]
hook.Add( "CH_AdvMedic_OnBodyRemoved", "CH_Medic.InvestigationMod", function( pPlayer, bRevived )
	if not bRevived then
                timer.Simple( 0.2, function()
                        if pPlayer.IM_tDamageInfos then
                                pPlayer:IM_DeathBody( pPlayer.IM_tDamageInfos.DamageType, pPlayer.IM_tDamageInfos.Criminal, pPlayer.IM_tDamageInfos.Pos, pPlayer.IM_tDamageInfos.Model )
                                pPlayer.IM_tDamageInfos = nil
                        end
                end )
	else
		timer.Simple( 1, function()
			if IsValid( InvestigationMod.DeathBodies[ pPlayer ] ) then
				if IsValid( InvestigationMod.DeathBodies[ pPlayer ]:GetParent() ) then
					InvestigationMod.DeathBodies[ pPlayer ]:GetParent():Remove()
				end
				InvestigationMod.DeathBodies[ pPlayer ]:Remove()
			end
		end )
	end
end ) 
