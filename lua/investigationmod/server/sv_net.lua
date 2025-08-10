util.AddNetworkString( "InvestigationMod.Pack" )
util.AddNetworkString( "InvestigationMod.AskPrints" )
util.AddNetworkString( "InvestigationMod.SendFootPrints" )
util.AddNetworkString( "InvestigationMod.SendDoorPrints" )
util.AddNetworkString( "InvestigationMod.BodyToMorgue" )
util.AddNetworkString( "InvestigationMod.TakeFingerprint" )
util.AddNetworkString( "InvestigationMod.BurnBody" )

net.Receive( "InvestigationMod.BurnBody", function( len, pCaller )
	if not pCaller:Alive() then return end
	if not InvestigationMod:GetConfig( "CanBurnBody" ) then return end
	if InvestigationMod:IsAllowedToInvestigate( pCaller ) then return end

	local eCube = net.ReadEntity()

	if not IsValid( eCube ) then return end
	if not IsValid( eCube:GetCriminal() ) or eCube:GetCriminal() ~= pCaller then return end
	if eCube:GetPos():DistToSqr( pCaller:GetPos() ) > 25000 then return end

	eCube:Burn()
end )

net.Receive( "InvestigationMod.AskPrints", function( len, pCaller ) 
	if not pCaller:Alive() then return end
	if not InvestigationMod:IsAllowedToInvestigate( pCaller ) then return end

	pCaller:IM_SendFootprints()
	pCaller:IM_SendDoorFinger()
end )

net.Receive( "InvestigationMod.Pack", function( len, pCaller )
	if not pCaller:Alive() then return end
	if not InvestigationMod:IsAllowedToInvestigate( pCaller ) then return end

	local eBullet = net.ReadEntity()

	if not IsValid( eBullet ) then return end

	eBullet:Pack( pCaller )
end )

net.Receive( "InvestigationMod.TakeFingerprint", function( len, pCaller )
	if not pCaller:Alive() then return end
	if not InvestigationMod:IsAllowedToInvestigate( pCaller ) then return end

	local sPlayer = net.ReadString()
	local iDoor = net.ReadUInt( 16 )

	InvestigationMod.RemoveDoorFinger( iDoor, sPlayer )

	pCaller:IM_SendDoorFinger()
end )

net.Receive( "InvestigationMod.BodyToMorgue", function( len, pCaller )
	if not pCaller:Alive() then return end
	if not InvestigationMod:IsAllowedToInvestigate( pCaller ) then return end

	local eRagdoll = net.ReadEntity()
	if IsValid( eRagdoll ) and eRagdoll:GetClass() == "prop_ragdoll" and eRagdoll:GetPos():DistToSqr( pCaller:GetPos() ) < 20000 then
		timer.Create( "DisappearRagdoll" .. eRagdoll:EntIndex(), 0.1, 10, function()
			if not IsValid( eRagdoll ) then eRagdoll:Remove() end
			
			eRagdoll:SetRenderMode( RENDERMODE_TRANSALPHA )
			eRagdoll:SetColor( Color( 255, 255, 255, eRagdoll:GetColor().a * 0.5 ) )

			if timer.RepsLeft( "DisappearRagdoll" .. eRagdoll:EntIndex() ) == 0 then
				if IsValid( eRagdoll ) then
					if IsValid( eRagdoll:GetParent() ) then
						eRagdoll:GetParent():Remove()
					end	
					eRagdoll:Remove()
				end
			end
		end )
	end
end )