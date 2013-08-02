AddCSLuaFile("autorun/client/cl_hitdamagenumbers.lua")

util.AddNetworkString( "net_HDN_initialize" )
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
SetGlobalBool( "HDN_AllowUserToggle", false )
cvars.AddChangeCallback( "sv_hitnums_allowusertoggle", function()
	local allow = (GetConVarNumber("sv_hitnums_allowusertoggle") ~= 0)
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
SetGlobalBool( "HDN_IgnoreZ", false )
cvars.AddChangeCallback( "sv_hitnums_ignorez", function()
	SetGlobalBool("HDN_IgnoreZ", GetConVarNumber("sv_hitnums_ignorez") ~= 0)
end )

// Size-scale of all indicators.
CreateConVar( "sv_hitnums_scale", 0.3 )
SetGlobalFloat( "HDN_Scale", 0.3 )
cvars.AddChangeCallback( "sv_hitnums_scale", function()
	SetGlobalFloat("HDN_Scale", GetConVarNumber("sv_hitnums_scale"))
end )

// Time-to-live. In seconds, how long until the indicator is faded completely and deleted.
CreateConVar( "sv_hitnums_ttl", 1.0 )
SetGlobalFloat( "HDN_TTL", 1.0 )
cvars.AddChangeCallback( "sv_hitnums_ttl", function()
	SetGlobalFloat("HDN_TTL", GetConVarNumber("sv_hitnums_ttl"))
end )

// Time-to-live. In seconds, how long until the indicator is faded completely and deleted.
CreateConVar( "sv_hitnums_showsign", 1 )
SetGlobalBool( "HDN_ShowSign", true )
cvars.AddChangeCallback( "sv_hitnums_showsign", function()
	SetGlobalBool("HDN_ShowSign", GetConVarNumber("sv_hitnums_showsign") ~= 0)
end )

// Transparency/Alpha multiplier.
CreateConVar( "sv_hitnums_alpha", 1.0 )
SetGlobalFloat( "HDN_AlphaMul", 1.0 )
cvars.AddChangeCallback( "sv_hitnums_alpha", function()
	SetGlobalInt("HDN_AlphaMul", math.Clamp(GetConVarNumber("sv_hitnums_alpha"), 0, 1))
end )

// Critical indicator mode.
// 0 = No Crit (Damage is shown, but not in critical colour)
// 1 = "<dmg>" (Damage only, in critical colour)
// 2 = "Crit!"
// 3 = "Critical!"
// 4 = "Crit <dmg>"
// 5 = "Critical <dmg>"
// 6 = "Crit!" AND "<dmg>"
// 7 = "Critical!" AND "<dmg>"
CreateConVar( "sv_hitnums_critmode", 7 )
SetGlobalInt( "HDN_CritMode", 7 )
cvars.AddChangeCallback( "sv_hitnums_critmode", function()
	SetGlobalInt("HDN_CritMode", GetConVarNumber("sv_hitnums_critmode"))
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


// Fontface.
local font_name = "coolvetica"
local font_size = 50
local font_weight = 800
local font_underline = false
local font_italic = false
local font_shadow = false
local font_additive = false
local font_outline = true

CreateConVar( "sv_hitnums_font_name", "coolvetica" )
cvars.AddChangeCallback( "sv_hitnums_font_name", function()
	font_name = GetConVarString("sv_hitnums_font_name")
end )

CreateConVar( "sv_hitnums_font_size", 50 )
cvars.AddChangeCallback( "sv_hitnums_font_size", function()
	font_size = GetConVarNumber("sv_hitnums_font_size")
end )

CreateConVar( "sv_hitnums_font_weight", 800 )
cvars.AddChangeCallback( "sv_hitnums_font_weight", function()
	font_weight = GetConVarNumber("sv_hitnums_font_weight")
end )

CreateConVar( "sv_hitnums_font_underline", 0 )
cvars.AddChangeCallback( "sv_hitnums_font_underline", function()
	font_underline = (GetConVarNumber("sv_hitnums_font_underline") ~= 0)
end )

CreateConVar( "sv_hitnums_font_italic", 0 )
cvars.AddChangeCallback( "sv_hitnums_font_italic", function()
	font_italic = (GetConVarNumber("sv_hitnums_font_italic") ~= 0)
end )

CreateConVar( "sv_hitnums_font_shadow", 0 )
cvars.AddChangeCallback( "sv_hitnums_font_shadow", function()
	font_shadow = (GetConVarNumber("sv_hitnums_font_shadow") ~= 0)
end )

CreateConVar( "sv_hitnums_font_additive", 0 )
cvars.AddChangeCallback( "sv_hitnums_font_additive", function()
	font_additive = (GetConVarNumber("sv_hitnums_font_additive") ~= 0)
end )

CreateConVar( "sv_hitnums_font_outline", 1 )
cvars.AddChangeCallback( "sv_hitnums_font_outline", function()
	font_outline = (GetConVarNumber("sv_hitnums_font_outline") ~= 0)
end )


// Colours.
CreateConVar( "sv_hitnums_color_generic", "FFE6D2" )
SetGlobalInt("HDN_Col_Gen", 16770770)
cvars.AddChangeCallback( "sv_hitnums_color_generic", function()
	SetGlobalInt("HDN_Col_Gen", tonumber("0x"..GetConVarString("sv_hitnums_color_generic"):sub(1,6)))
end )

CreateConVar( "sv_hitnums_color_critical", "FF2828" )
SetGlobalInt("HDN_Col_Crit", 16721960)
cvars.AddChangeCallback( "sv_hitnums_color_critical", function()
	SetGlobalInt("HDN_Col_Crit", tonumber("0x"..GetConVarString("sv_hitnums_color_critical"):sub(1,6)))
end )

CreateConVar( "sv_hitnums_color_fire", "FF7800" )
SetGlobalInt("HDN_Col_Fire", 16742400)
cvars.AddChangeCallback( "sv_hitnums_color_fire", function()
	SetGlobalInt("HDN_Col_Fire", tonumber("0x"..GetConVarString("sv_hitnums_color_fire"):sub(1,6)))
end )

CreateConVar( "sv_hitnums_color_explosion", "F0F032" )
SetGlobalInt("HDN_Col_Expl", 15790130)
cvars.AddChangeCallback( "sv_hitnums_color_explosion", function()
	SetGlobalInt("HDN_Col_Expl", tonumber("0x"..GetConVarString("sv_hitnums_color_explosion"):sub(1,6)))
end )

CreateConVar( "sv_hitnums_color_acid", "8CFF4B" )
SetGlobalInt("HDN_Col_Acid", 9240395)
cvars.AddChangeCallback( "sv_hitnums_color_acid", function()
	SetGlobalInt("HDN_Col_Acid", tonumber("0x"..GetConVarString("sv_hitnums_color_acid"):sub(1,6)))
end )

CreateConVar( "sv_hitnums_color_electric", "64A0FF" )
SetGlobalInt("HDN_Col_Elec", 6594815)
cvars.AddChangeCallback( "sv_hitnums_color_electric", function()
	SetGlobalInt("HDN_Col_Elec", tonumber("0x"..GetConVarString("sv_hitnums_color_electric"):sub(1,6)))
end )


local function entIsWorld(ent)
	
	if ent:IsWorld() then
		return true
	end
	
	local class = ent:GetClass()
	
	return string.StartWith(class, "func_")
		or string.StartWith(class, "prop_door")
	
end


local function entIsProp(ent)
	
	local class = ent:GetClass()
	return string.StartWith(class, "prop_dynamic") or string.StartWith(class, "prop_physics")
	
end


hook.Add( "PlayerAuthed", "hdn_initializePlayer", function(pl)
	
	net.Start("net_HDN_initialize")

	net.WriteString(font_name)
	net.WriteUInt(font_size, 32)
	net.WriteUInt(font_weight, 32)
	net.WriteBit(font_underline)
	net.WriteBit(font_italic)
	net.WriteBit(font_shadow)
	net.WriteBit(font_additive)
	net.WriteBit(font_outline)
	
	net.Send(pl)
	
end )


hook.Add( "EntityTakeDamage", "hdn_onEntDamage", function(target, dmginfo)
	
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
			if dmginfo:IsBulletDamage()or dmginfo:GetDamageType() == DMG_CLUB then
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
