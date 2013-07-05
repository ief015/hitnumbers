AddCSLuaFile("autorun/client/cl_hitdamagenumbers.lua")

util.AddNetworkString( "net_HDN_createInd" )
util.AddNetworkString( "net_HDN_forceToggleOn" )


// Enable/Disable this addon globally.
local on = true
CreateConVar( "sv_hitnums_enable", 1 )
cvars.AddChangeCallback( "sv_hitnums_enable", function()
	on = (GetConVarNumber("sv_hitnums_enable") ~= 0)
end )

// Allow clients to hide this addon for themselves.
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

// Show all damage being made thoughout the server for all clients.
local showAll = false
CreateConVar( "sv_hitnums_showalldamage", 0 )
cvars.AddChangeCallback( "sv_hitnums_showalldamage", function()
	showAll = (GetConVarNumber("sv_hitnums_showalldamage") ~= 0)
end )

// Only show indicators for targets that actually have health and/or is breakable.
local breakablesOnly = true
CreateConVar( "sv_hitnums_breakablesonly", 1 )
cvars.AddChangeCallback( "sv_hitnums_breakablesonly", function()
	breakablesOnly = (GetConVarNumber("sv_hitnums_breakablesonly") ~= 0)
end )

// Ignore depth for all clients during rendering. Basically when enabled, you can see the indicators through walls and objects.
CreateConVar( "sv_hitnums_ignorez", 0 )
SetGlobalBool("HDN_IgnoreZ", false)
cvars.AddChangeCallback( "sv_hitnums_ignorez", function()
	SetGlobalBool("HDN_IgnoreZ", GetConVarNumber("sv_hitnums_ignorez") ~= 0)
end )


// Masks.
local mask_players = true
local mask_npcs = true
local mask_ragdolls = true
local mask_vehicles = true
local mask_props = true
local mask_world = false

CreateConVar( "sv_hitnums_mask_players", 1 )
cvars.AddChangeCallback( "sv_hitnums_mask_players", function()
	mask_players = (GetConVarNumber("sv_hitnums_mask_players") ~= 0)
end )

CreateConVar( "sv_hitnums_mask_npcs", 1 )
cvars.AddChangeCallback( "sv_hitnums_mask_npcs", function()
	mask_npcs = (GetConVarNumber("sv_hitnums_mask_npcs") ~= 0)
end )

CreateConVar( "sv_hitnums_mask_ragdolls", 1 )
cvars.AddChangeCallback( "sv_hitnums_mask_ragdolls", function()
	mask_ragdolls = (GetConVarNumber("sv_hitnums_mask_ragdolls") ~= 0)
end )

CreateConVar( "sv_hitnums_mask_vehicles", 1 )
cvars.AddChangeCallback( "sv_hitnums_mask_vehicles", function()
	mask_vehicles = (GetConVarNumber("sv_hitnums_mask_vehicles") ~= 0)
end )

CreateConVar( "sv_hitnums_mask_props", 1 )
cvars.AddChangeCallback( "sv_hitnums_mask_props", function()
	mask_props = (GetConVarNumber("sv_hitnums_mask_props") ~= 0)
end )

CreateConVar( "sv_hitnums_mask_world", 0 )
cvars.AddChangeCallback( "sv_hitnums_mask_world", function()
	mask_world = (GetConVarNumber("sv_hitnums_mask_world") ~= 0)
end )



function entIsWorld(ent)
	
	if ent:IsWorld() then
		return true
	end
	
	local class = ent:GetClass()
	return string.StartWith(class, "func_")
	
end


function entIsProp(ent)
	
	local class = ent:GetClass()
	return string.StartWith(class, "prop_dynamic") or string.StartWith(class, "prop_physics")
	
end


hook.Add( "EntityTakeDamage", "hdn_onEntDamage", function (target, dmginfo)
	
	if not on then return end
	
	local attacker = dmginfo:GetAttacker()
	
	if target:IsValid() then
		
		if  ( attacker:IsPlayer() or showAll )
		and ( !breakablesOnly or target:Health() > 0 )
		and ( target:GetCollisionGroup() ~= COLLISION_GROUP_DEBRIS )
		and ( attacker != target or showAll )
		then
			
			// Check masks.
			if ( !mask_players and target:IsPlayer() )
			or ( !mask_npcs and target:IsNPC() )
			or ( !mask_ragdolls and target:IsRagdoll() )
			or ( !mask_vehicles and target:IsVehicle() )
			or ( !mask_props and entIsProp(target) )
			or ( !mask_world and entIsWorld(target) )
			then
				return
			end
			
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
