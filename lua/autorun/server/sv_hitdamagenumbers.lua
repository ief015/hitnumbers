AddCSLuaFile("autorun/client/cl_hitdamagenumbers.lua")

util.AddNetworkString( "hdn_initPly" )
util.AddNetworkString( "hdn_spawn" )
util.AddNetworkString( "hdn_refreshColours" )
util.AddNetworkString( "hdn_forceToggleOn" )


-- Enable/Disable this addon globally.
local on = true
CreateConVar( "sv_hitnums_enable", 1 )
cvars.AddChangeCallback( "sv_hitnums_enable", function()
	on = (GetConVarNumber("sv_hitnums_enable") ~= 0)
end )

-- Allow clients to hide this addon for themselves.
CreateConVar( "sv_hitnums_allowusertoggle", 0 )
SetGlobalBool( "HDN_AllowUserToggle", false )
cvars.AddChangeCallback( "sv_hitnums_allowusertoggle", function()
	local allow = (GetConVarNumber("sv_hitnums_allowusertoggle") ~= 0)
	SetGlobalBool("HDN_AllowUserToggle", allow)
	if not allow then
		net.Start("hdn_forceToggleOn")
		net.Broadcast()
	end
end )

-- Show all damage being made throughout the server for all clients.
local showAll = false
CreateConVar( "sv_hitnums_showalldamage", 0 )
cvars.AddChangeCallback( "sv_hitnums_showalldamage", function()
	showAll = (GetConVarNumber("sv_hitnums_showalldamage") ~= 0)
end )

-- Only show indicators for targets that actually have health and/or is breakable.
local breakablesOnly = true
CreateConVar( "sv_hitnums_breakablesonly", 1 )
cvars.AddChangeCallback( "sv_hitnums_breakablesonly", function()
	breakablesOnly = (GetConVarNumber("sv_hitnums_breakablesonly") ~= 0)
end )

-- Ignore depth for all clients during rendering. Basically when enabled, you can see the indicators through walls and objects.
CreateConVar( "sv_hitnums_ignorez", 0 )
SetGlobalBool( "HDN_IgnoreZ", false )
cvars.AddChangeCallback( "sv_hitnums_ignorez", function()
	SetGlobalBool("HDN_IgnoreZ", GetConVarNumber("sv_hitnums_ignorez") ~= 0)
end )

-- Size-scale of all indicators.
CreateConVar( "sv_hitnums_scale", 0.3 )
SetGlobalFloat( "HDN_Scale", 0.3 )
cvars.AddChangeCallback( "sv_hitnums_scale", function()
	SetGlobalFloat("HDN_Scale", GetConVarNumber("sv_hitnums_scale"))
end )

-- Time-to-live. In seconds, how long until the indicator is faded completely and deleted.
CreateConVar( "sv_hitnums_ttl", 1.0 )
SetGlobalFloat( "HDN_TTL", 1.0 )
cvars.AddChangeCallback( "sv_hitnums_ttl", function()
	SetGlobalFloat("HDN_TTL", GetConVarNumber("sv_hitnums_ttl"))
end )

-- Time-to-live. In seconds, how long until the indicator is faded completely and deleted.
CreateConVar( "sv_hitnums_showsign", 1 )
SetGlobalBool( "HDN_ShowSign", true )
cvars.AddChangeCallback( "sv_hitnums_showsign", function()
	SetGlobalBool("HDN_ShowSign", GetConVarNumber("sv_hitnums_showsign") ~= 0)
end )

-- Transparency/Alpha multiplier.
CreateConVar( "sv_hitnums_alpha", 1.0 )
SetGlobalFloat( "HDN_AlphaMul", 1.0 )
cvars.AddChangeCallback( "sv_hitnums_alpha", function()
	SetGlobalInt("HDN_AlphaMul", math.Clamp(GetConVarNumber("sv_hitnums_alpha"), 0, 1))
end )

-- Critical indicator mode.
-- 0 = No Crit (Damage is shown, but not in critical colour)
-- 1 = "<dmg>" (Damage only, in critical colour)
-- 2 = "Crit!"
-- 3 = "Critical!"
-- 4 = "Crit <dmg>"
-- 5 = "Critical <dmg>"
-- 6 = "Crit!" AND "<dmg>"
-- 7 = "Critical!" AND "<dmg>"
CreateConVar( "sv_hitnums_critmode", 7 )
SetGlobalInt( "HDN_CritMode", 7 )
cvars.AddChangeCallback( "sv_hitnums_critmode", function()
	SetGlobalInt("HDN_CritMode", GetConVarNumber("sv_hitnums_critmode"))
end )

CreateConVar( "sv_hitnums_animate", 1 )
SetGlobalInt( "HDN_Animation", 1 )
cvars.AddChangeCallback( "sv_hitnums_animate", function()
	SetGlobalInt("HDN_Animation", GetConVarNumber("sv_hitnums_animate"))
end )

CreateConVar( "sv_hitnums_gravity", 1 )
SetGlobalFloat( "HDN_Gravity", 1 )
cvars.AddChangeCallback( "sv_hitnums_gravity", function()
	SetGlobalFloat("HDN_Gravity", GetConVarNumber("sv_hitnums_gravity"))
end )

CreateConVar( "sv_hitnums_forceinheritance", 1 )
SetGlobalFloat( "HDN_ForceInheritance", 1 )
cvars.AddChangeCallback( "sv_hitnums_forceinheritance", function()
	SetGlobalFloat("HDN_ForceInheritance", GetConVarNumber("sv_hitnums_forceinheritance"))
end )

CreateConVar( "sv_hitnums_forceoffset_xmin", -0.5 )
SetGlobalFloat( "HDN_ForceOffset_XMin", -0.5 )
cvars.AddChangeCallback( "sv_hitnums_forceoffset_xmin", function()
	SetGlobalFloat("HDN_ForceOffset_XMin", GetConVarNumber("sv_hitnums_forceoffset_xmin"))
end )

CreateConVar( "sv_hitnums_forceoffset_xmax", 0.5 )
SetGlobalFloat( "HDN_ForceOffset_XMax", 0.5 )
cvars.AddChangeCallback( "sv_hitnums_forceoffset_xmax", function()
	SetGlobalFloat("HDN_ForceOffset_XMax", GetConVarNumber("sv_hitnums_forceoffset_xmax"))
end )

CreateConVar( "sv_hitnums_forceoffset_ymin", -0.5 )
SetGlobalFloat( "HDN_ForceOffset_YMin", -0.5 )
cvars.AddChangeCallback( "sv_hitnums_forceoffset_ymin", function()
	SetGlobalFloat("HDN_ForceOffset_YMin", GetConVarNumber("sv_hitnums_forceoffset_ymin"))
end )

CreateConVar( "sv_hitnums_forceoffset_ymax", 0.5 )
SetGlobalFloat( "HDN_ForceOffset_YMax", 0.5 )
cvars.AddChangeCallback( "sv_hitnums_forceoffset_ymax", function()
	SetGlobalFloat("HDN_ForceOffset_YMax", GetConVarNumber("sv_hitnums_forceoffset_ymax"))
end )

CreateConVar( "sv_hitnums_forceoffset_zmin", 0.75 )
SetGlobalFloat( "HDN_ForceOffset_ZMin", 0.75 )
cvars.AddChangeCallback( "sv_hitnums_forceoffset_zmin", function()
	SetGlobalFloat("HDN_ForceOffset_ZMin", GetConVarNumber("sv_hitnums_forceoffset_zmin"))
end )

CreateConVar( "sv_hitnums_forceoffset_zmax", 1.0 )
SetGlobalFloat( "HDN_ForceOffset_ZMax", 1.0 )
cvars.AddChangeCallback( "sv_hitnums_forceoffset_zmax", function()
	SetGlobalFloat("HDN_ForceOffset_ZMax", GetConVarNumber("sv_hitnums_forceoffset_zmax"))
end )

-- Damage masks.
local mask_players  = true
local mask_npcs     = true
local mask_ragdolls = true
local mask_vehicles = true
local mask_props    = true
local mask_world    = false

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


-- Font face.
local font_name      = "coolvetica"
local font_size      = 50
local font_weight    = 800
local font_underline = false
local font_italic    = false
local font_shadow    = false
local font_additive  = false
local font_outline   = true

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


-- Colours.
CreateConVar( "sv_hitnums_color_generic", "FFE6D2" )
SetGlobalInt("HDN_Col_Gen", 16770770)
cvars.AddChangeCallback( "sv_hitnums_color_generic", function()
	SetGlobalInt("HDN_Col_Gen", tonumber("0x"..GetConVarString("sv_hitnums_color_generic"):sub(1,6)))
	net.Start("hdn_refreshColours")
	net.Broadcast()
end )

CreateConVar( "sv_hitnums_color_critical", "FF2828" )
SetGlobalInt("HDN_Col_Crit", 16721960)
cvars.AddChangeCallback( "sv_hitnums_color_critical", function()
	SetGlobalInt("HDN_Col_Crit", tonumber("0x"..GetConVarString("sv_hitnums_color_critical"):sub(1,6)))
	net.Start("hdn_refreshColours")
	net.Broadcast()
end )

CreateConVar( "sv_hitnums_color_fire", "FF7800" )
SetGlobalInt("HDN_Col_Fire", 16742400)
cvars.AddChangeCallback( "sv_hitnums_color_fire", function()
	SetGlobalInt("HDN_Col_Fire", tonumber("0x"..GetConVarString("sv_hitnums_color_fire"):sub(1,6)))
	net.Start("hdn_refreshColours")
	net.Broadcast()
end )

CreateConVar( "sv_hitnums_color_explosion", "F0F032" )
SetGlobalInt("HDN_Col_Expl", 15790130)
cvars.AddChangeCallback( "sv_hitnums_color_explosion", function()
	SetGlobalInt("HDN_Col_Expl", tonumber("0x"..GetConVarString("sv_hitnums_color_explosion"):sub(1,6)))
	net.Start("hdn_refreshColours")
	net.Broadcast()
end )

CreateConVar( "sv_hitnums_color_acid", "8CFF4B" )
SetGlobalInt("HDN_Col_Acid", 9240395)
cvars.AddChangeCallback( "sv_hitnums_color_acid", function()
	SetGlobalInt("HDN_Col_Acid", tonumber("0x"..GetConVarString("sv_hitnums_color_acid"):sub(1,6)))
	net.Start("hdn_refreshColours")
	net.Broadcast()
end )

CreateConVar( "sv_hitnums_color_electric", "64A0FF" )
SetGlobalInt("HDN_Col_Elec", 6594815)
cvars.AddChangeCallback( "sv_hitnums_color_electric", function()
	SetGlobalInt("HDN_Col_Elec", tonumber("0x"..GetConVarString("sv_hitnums_color_electric"):sub(1,6)))
	net.Start("hdn_refreshColours")
	net.Broadcast()
end )


local nWarnings = 0

local function printWarning(msg)
	
	MsgC(Color(255, 50, 0), "[HitNumbers] WARNING: ")
	Msg(tostring(msg))
	
	nWarnings = nWarnings + 1
	
end


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
	
	return string.StartWith(class, "prop_dynamic")
	    or string.StartWith(class, "prop_physics")
	
end


local function spawnIndicator(dmgAmount, dmgType, dmgPosition, dmgForce, isCrit, target, reciever)
	
	net.Start("hdn_spawn", true)
	
	-- Damage amount.
	net.WriteFloat(dmgAmount)
	
	-- Type of damage.
	net.WriteUInt(dmgType, 32)
	
	-- Is critical.
	net.WriteBit(isCrit)
	
	-- Damage position.
	net.WriteVector(dmgPosition)
	
	-- Force of damage.
	net.WriteVector(dmgForce)
	
	-- Send indicator to receiver, else all players.
	if reciever == nil then
		if target == nil then
			net.Broadcast()
		else
			net.SendOmit(target)
		end
	else
		net.Send(reciever)
	end
	
end


hook.Add( "EntityTakeDamage", "hdn_onEntDamage_recordLastHealth", function(target, dmginfo)
	
	-- This is needed to determine if a player/entity had a health pool
	-- before being killed. Used in "hdn_onEntDamage" hook.
	
	-- This is awful, inelegant, and I hate it. But, it does work.
	-- This solution is temporary until I can find a better way around this. Thankfully, this
	-- is a fairly lightweight bandaid fix and overhead should be tiny, especially since an
	-- entity's lua table is serverside only.
	
	if not on then return end
	if not target:IsValid() then return end
	if target:GetCollisionGroup() == COLLISION_GROUP_DEBRIS then return end
	
	target.hdn_lastHealth = target:Health()
	
end )


hook.Add( "PostEntityTakeDamage", "hdn_onEntDamage", function(target, dmginfo)
	
	if not on then return end
	if not target:IsValid() then return end
	if target:GetCollisionGroup() == COLLISION_GROUP_DEBRIS then return end
	
	local attacker         = dmginfo:GetAttacker()
	local attackerIsPlayer = attacker:IsPlayer()
	
	if not ( attackerIsPlayer or showAll ) then return end
	if target.hdn_lastHealth == nil then
		if not ( not breakablesOnly or target:Health() > 0 ) then return end
	else
		if not ( not breakablesOnly or target.hdn_lastHealth > 0 ) then return end
	end
	if not ( attacker ~= target or showAll ) then return end
	
	local targetIsPlayer = target:IsPlayer()
	local targetIsNPC    = target:IsNPC()
	
	-- Check masks.
	if ( not mask_players and targetIsPlayer )
	or ( not mask_npcs and targetIsNPC )
	or ( not mask_ragdolls and target:IsRagdoll() )
	or ( not mask_vehicles and target:IsVehicle() )
	or ( not mask_props and entIsProp(target) )
	or ( not mask_world and entIsWorld(target) )
	then return end
	
	local dmgAmount = dmginfo:GetDamage()
	local dmgType   = dmginfo:GetDamageType()
	
	-- Get damage position.
	local pos = nil
	if dmginfo:IsBulletDamage() then
		
		pos = dmginfo:GetDamagePosition()
		
	elseif (attackerIsPlayer or attacker:IsNPC()) and
		   (dmgType == DMG_CLUB or dmgType == DMG_SLASH) then
		
		pos = util.TraceHull({
			start  = attacker:GetShootPos(),
			endpos = attacker:GetShootPos() + (attacker:GetAimVector() * 100),
			filter = attacker,
			mins   = Vector(-10,-10,-10),
			maxs   = Vector( 10, 10, 10),
			mask   = MASK_SHOT_HULL,
		}).HitPos
		
	end
	
	if pos == nil then
		
		-- Default damage position if no damage position could be calculated.
		pos = target:LocalToWorld(target:OBBCenter())
		
	end
	
	-- Get force of damage.
	local force = nil
	if dmginfo:IsExplosionDamage() then
		force = dmginfo:GetDamageForce() / 4000
	else
		force = -dmginfo:GetDamageForce() / 1000
	end
	force.x = math.Clamp(force.x, -1, 1)
	force.y = math.Clamp(force.y, -1, 1)
	force.z = math.Clamp(force.z, -1, 1)
	
	-- Is it a critical hit? (For players and npcs only)
	local isCrit = (dmgAmount >= target:GetMaxHealth()) and
				   (targetIsPlayer or targetIsNPC)
	
	-- Create and send the indicator to players.
	if showAll then
		if targetIsPlayer then
			spawnIndicator(dmgAmount, dmgType, pos, force, isCrit, target, nil)
		else
			spawnIndicator(dmgAmount, dmgType, pos, force, isCrit, nil, nil)
		end
	else
		spawnIndicator(dmgAmount, dmgType, pos, force, isCrit, target, attacker)
	end
	
end )


local function loadSettings()
	
	if file.Exists('hitnumbers/settings.txt', 'DATA') then
		
		local data = file.Read('hitnumbers/settings.txt', 'DATA')
		
		local t = util.JSONToTable(data or "{}")
		
		if t == nil then
			printWarning("Hit Numbers settings file ('data/hitnumbers/settings.txt') appears to be corrupt and won't be loaded. Please validate that the file is in proper JSON format! In the meantime, a backup of the settings file has been saved. ('data/hitnumbers/settings.backup.txt')\n")
			
			file.Write('hitnumbers/settings.backup.txt', data);
			
			-- Build a new settings file.
			return false
		end
		
		for k,v in pairs(t) do
			RunConsoleCommand('sv_hitnums_' .. k, v)
		end
		
		return true
		
	end
	
	-- No settings file exists.
	return false
end


local function saveSettings()
	
	if not file.Exists('hitnumbers', 'DATA') then
		file.CreateDir('hitnumbers')
	end
	
	local t = {}
	
	-- sv_hitnums_* commands
	for k,v in ipairs({
		'enable', 'allowusertoggle', 'showalldamage', 'breakablesonly', 'ignorez', 'scale', 'ttl', 'showsign', 'alpha', 'critmode', 'animate',
		'gravity', 'forceinheritance', 'forceoffset_xmin', 'forceoffset_xmax', 'forceoffset_ymin', 'forceoffset_ymax', 'forceoffset_zmin', 'forceoffset_zmax',
		'mask_players', 'mask_npcs', 'mask_ragdolls', 'mask_vehicles', 'mask_props', 'mask_world',
		'font_name', 'font_size', 'font_weight', 'font_underline', 'font_italic', 'font_shadow', 'font_additive', 'font_outline',
		'color_generic', 'color_critical', 'color_fire', 'color_explosion', 'color_acid', 'color_electric', 
	}) do
		
		t[v] = GetConVarString('sv_hitnums_' .. v)
		
	end
	
	file.Write('hitnumbers/settings.txt', util.TableToJSON(t))
	
end


hook.Add( "ShutDown", "hdn_saveSettings", function()
	
	saveSettings()
	
end)


hook.Add( "PlayerAuthed", "hdn_initializePlayer", function(pl)
	
	net.Start("hdn_initPly")

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


-- Load server settings.
if not loadSettings() then
	saveSettings()
end


Msg("-- Hit Numbers loaded --")
if nWarnings > 0 then
	MsgN(" (with " .. nWarnings .. " warning" .. (nWarnings == 1 and "" or "s") .. ")")
else
	MsgN()
end