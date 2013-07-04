AddCSLuaFile("autorun/client/cl_hitdamagenumbers.lua")

util.AddNetworkString( "net_HDN_createInd" )
util.AddNetworkString( "net_HDN_forceToggleOn" )


local on = true
CreateConVar( "sv_hitnums_enable", 1 )
cvars.AddChangeCallback( "sv_hitnums_enable", function()
	on = (GetConVarNumber("sv_hitnums_enable") ~= 0)
end )


CreateConVar( "sv_hitnums_allowusertoggle", 0 )
SetGlobalBool("HDN_AllowUserToggle", false)
cvars.AddChangeCallback( "sv_hitnums_allowusertoggle", function()
	local allow = GetConVarNumber("sv_hitnums_allowusertoggle") ~= 0
	SetGlobalBool("HDN_AllowUserToggle", allow)
	if not allow then
		net.Start("net_HDN_forceToggleOn")
		net.Broadcast()
	end
end )


local showAll = false
CreateConVar( "sv_hitnums_showalldamage", 0 )
cvars.AddChangeCallback( "sv_hitnums_showalldamage", function()
	showAll = (GetConVarNumber("sv_hitnums_showalldamage") ~= 0)
end )


local breakablesOnly = true
CreateConVar( "sv_hitnums_breakablesonly", 1 )
cvars.AddChangeCallback( "sv_hitnums_breakablesonly", function()
	breakablesOnly = (GetConVarNumber("sv_hitnums_breakablesonly") ~= 0)
end )


CreateConVar( "sv_hitnums_ignorez", 0 )
SetGlobalBool("HDN_IgnoreZ", false)
cvars.AddChangeCallback( "sv_hitnums_ignorez", function()
	SetGlobalBool("HDN_IgnoreZ", GetConVarNumber("sv_hitnums_ignorez") ~= 0)
end )


hook.Add( "EntityTakeDamage", "hdn_onEntDamage", function (target, dmginfo)
	
	if not on then return end
	
	local attacker = dmginfo:GetAttacker()
	
	if target:IsValid() then
		
		if (attacker:IsPlayer() or showAll) and (!breakablesOnly or target:Health()>0)
			and (target:GetCollisionGroup() ~= COLLISION_GROUP_DEBRIS)
			and (attacker != target or showAll) then
		
			net.Start("net_HDN_createInd")
			
			// Damage amount.
			net.WriteFloat(dmginfo:GetDamage())
			
			// Type of damage.
			net.WriteUInt(dmginfo:GetDamageType(), 32)
			
			// Is it a critical hit? (For players and npcs only)
			net.WriteBit( (dmginfo:GetDamage() >= target:GetMaxHealth())
						and (target:IsPlayer() or target:IsNPC()) )
			
			// Get damage position.
			local pos
			if dmginfo:IsBulletDamage() then
				pos = dmginfo:GetDamagePosition()
			else
				if target:IsPlayer() or target:IsNPC() then
					pos = target:GetPos() + Vector(0,0,48)
				else
					pos = target:GetPos()
				end
				
			end
			net.WriteVector(pos)
			
			// Get force of damage.
			local force
			if dmginfo:IsExplosionDamage() then
				force = dmginfo:GetDamageForce() / 4000
			else
				force = -dmginfo:GetDamageForce() / 1000
			end
			force.x = math.Clamp(force.x, -1, 1)
			force.y = math.Clamp(force.y, -1, 1)
			force.z = math.Clamp(force.z, -1, 1)
			net.WriteVector(force)
			
			// Send indicator to player(s).
			if showAll then
				if target:IsPlayer() then
					net.SendOmit(target)
				else
					net.Broadcast()
				end
			else
				net.Send(attacker)
			end
			
		end
		
	end
	
end )
