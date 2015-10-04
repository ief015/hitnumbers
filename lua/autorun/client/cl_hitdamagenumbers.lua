local indicators = {}
local initialized = false
local lastcurtime = 0
local on = true

local debugger = {}
debugger.enabled = false
debugger.tickms = 0
debugger.renderms = 0
debugger.ticktimer = 0
debugger.rendertimer = 0
debugger.count = 0

local indicatorColors = {}

local CRIT_MODE = {}
CRIT_MODE.NONE                = 0
CRIT_MODE.DMG_ONLY            = 1
CRIT_MODE.CRIT_ONLY           = 2
CRIT_MODE.CRITICAL_ONLY       = 3
CRIT_MODE.CRIT_AND_DMG        = 4
CRIT_MODE.CRITICAL_AND_DMG    = 5
CRIT_MODE.CRIT_AND_DMG_EX     = 6
CRIT_MODE.CRITICAL_AND_DMG_EX = 7

local function invlerp(min, max, p)
--	if max-min == 0 then return 0 end
	return (p - min) / (max - min)
end

local ANIMATION_FUNC = {}
ANIMATION_FUNC[1] = function(p)
	if p <= 0.2 then
		local x = invlerp(0, 0.2, p)
		return x*3*0.25 + 0.25
	else
		local x = invlerp(0.2, 1, p)
		return ((-x + 1) / 2) + 0.5
	end
end
ANIMATION_FUNC[2] = function(p)
	if p <= 0.2 then
		local x = invlerp(0, 0.2, p)
		return x*3*0.25 + 0.25
	else
		return 1
	end
end
ANIMATION_FUNC[3] = function(p)
	return 1-p
end


-- Debug mode, shows performance.
CreateConVar( "hitnums_debugmode", 0 )
cvars.AddChangeCallback( "hitnums_debugmode", function()
	debugger.enabled = GetConVarNumber("hitnums_debugmode") ~= 0
end )


-- Client-side Hit Numbers show/hide concommand.
concommand.Add( "hitnums_toggle", function()
	
	if not GetGlobalBool("HDN_AllowUserToggle") then
		LocalPlayer():PrintMessage( HUD_PRINTTALK, "You do not have permission to hide the Hit Numbers indicators." )
		MsgN("You do not have permission to hide the Hit Numbers indicators. (Server convar 'sv_hitnums_allowusertoggle' is disabled)")
		return
	end
	
	on = not on
	
	if on then
		LocalPlayer():PrintMessage( HUD_PRINTTALK, "Damage indicators enabled." )
	else
		LocalPlayer():PrintMessage( HUD_PRINTTALK, "Damage indicators disabled." )
		table.Empty(indicators)
	end
	
end )


-- Build colour table from server-set colours.
local function buildColourTable()
	
	local col = GetGlobalInt("HDN_Col_Gen", 16770770)
	indicatorColors.gen = Color(bit.band(bit.rshift(col, 16), 255), bit.band(bit.rshift(col, 8), 255), bit.band(col, 255))
	
	col = GetGlobalInt("HDN_Col_Crit", 16721960)
	indicatorColors.crit = Color(bit.band(bit.rshift(col, 16), 255), bit.band(bit.rshift(col, 8), 255), bit.band(col, 255))
	
	col = GetGlobalInt("HDN_Col_Fire", 16742400)
	indicatorColors.fire = Color(bit.band(bit.rshift(col, 16), 255), bit.band(bit.rshift(col, 8), 255), bit.band(col, 255))
	
	col = GetGlobalInt("HDN_Col_Expl", 15790130)
	indicatorColors.expl = Color(bit.band(bit.rshift(col, 16), 255), bit.band(bit.rshift(col, 8), 255), bit.band(col, 255))
	
	col = GetGlobalInt("HDN_Col_Acid", 9240395)
	indicatorColors.acid = Color(bit.band(bit.rshift(col, 16), 255), bit.band(bit.rshift(col, 8), 255), bit.band(col, 255))
	
	col = GetGlobalInt("HDN_Col_Elec", 6594815)
	indicatorColors.elec = Color(bit.band(bit.rshift(col, 16), 255), bit.band(bit.rshift(col, 8), 255), bit.band(col, 255))
	
end
net.Receive( "hdn_refreshColours", function()
	timer.Simple(1.0, buildColourTable) -- Delay to allow Globals to sync.
end )


local function spawnIndicator(text, col, pos, vel, ttl)
	
	if not initialized then return end
	
	local ind = {}
	
	ind.text = text
	ind.pos = Vector(pos.x, pos.y, pos.z)
	ind.vel = Vector(vel.x, vel.y, vel.z)
	ind.col = Color(col.r, col.g, col.b)
	
	ind.ttl = ttl
	ind.life = ttl
	ind.spawntime = CurTime()
	
	surface.SetFont("font_HDN_Inds")
	local w, h = surface.GetTextSize(text)
	
	ind.widthH = w/2
	ind.heightH = h/2
	
	table.insert(indicators, ind)
	
end


local function populateSettingsPlayer(panel)
	
	if GetGlobalBool("HDN_AllowUserToggle") then
		
		panel:AddControl("Button", {
			Label = "Toggle Hit Numbers",
			Command = "hitnums_toggle",
		})
		
	end
	
end


-- Set up hit numbers.
net.Receive( "hdn_initPly", function()
	
	surface.CreateFont( "font_HDN_Inds", {
		font 		= net.ReadString(),
		size 		= net.ReadUInt(32),
		weight 		= net.ReadUInt(32),
		blursize 	= 0,
		scanlines 	= 0,
		antialias 	= false,
		underline 	= (net.ReadBit()~=0),
		italic 		= (net.ReadBit()~=0),
		strikeout 	= false,
		symbol 		= false,
		rotary 		= false,
		shadow 		= (net.ReadBit()~=0),
		additive 	= (net.ReadBit()~=0),
		outline 	= (net.ReadBit()~=0)
	} )
	
	buildColourTable()
	
	initialized = true
	
end )


net.Receive( "hdn_forceToggleOn", function()
	
	on = true
	
end )


-- Called when an indicator should be created for this player.
net.Receive( "hdn_spawn", function()
	
	if not on then return end
	
	-- Get damage type and amount.
	local dmg = net.ReadFloat()
	local dmgtype = net.ReadUInt(32)
	
	if dmg < 1 then dmg = math.Round(dmg, 3)
	else dmg = math.floor(dmg) end
	
	-- Get "critical hit" bit.
	local crit = (net.ReadBit() ~= 0)
	
	-- Retrieve position and force of the damage.
	local pos = net.ReadVector()
	local force = net.ReadVector() * GetGlobalFloat("HDN_ForceInheritance", 1.0)
	
	-- Set colour of indicator based on damage type (or critical hit).
	local col = indicatorColors.gen
	
	local ttl         = GetGlobalFloat("HDN_TTL", 1.0)
	local showsign    = GetGlobalBool("HDN_ShowSign", true)
	local critmode    = GetGlobalInt("HDN_CritMode", CRIT_MODE.CRITICAL_AND_DMG_EX) -- See "Critical indicator mode" in sv_hitdamagenumbers.lua
	
	local fxmin, fxmax = GetGlobalFloat("HDN_ForceOffset_XMin", -0.5), GetGlobalFloat("HDN_ForceOffset_XMax", 0.5)
	local fymin, fymax = GetGlobalFloat("HDN_ForceOffset_YMin", -0.5), GetGlobalFloat("HDN_ForceOffset_YMax", 0.5)
	local fzmin, fzmax = GetGlobalFloat("HDN_ForceOffset_ZMin", 0.75), GetGlobalFloat("HDN_ForceOffset_ZMax", 1.0)
	
	-- Is critical text indicator.
	if crit and critmode >= CRIT_MODE.CRIT_ONLY then
		
		local txt
		
		if critmode == CRIT_MODE.CRIT_ONLY or critmode == CRIT_MODE.CRIT_AND_DMG_EX then
			
			txt = "Crit!"
			
		elseif critmode == CRIT_MODE.CRITICAL_ONLY or critmode >= CRIT_MODE.CRITICAL_AND_DMG_EX then
			
			txt = "Critical!"
			
		elseif critmode == CRIT_MODE.CRIT_AND_DMG then
			
			txt = "Crit " .. ( showsign and tostring(-dmg) or tostring(math.abs(dmg)) )
			
		elseif critmode == CRIT_MODE.CRITICAL_AND_DMG then
			
			txt = "Critical " .. ( showsign and tostring(-dmg) or tostring(math.abs(dmg)) )
			
		else
			
			txt = "?"
			
		end
		
		spawnIndicator(txt, indicatorColors.crit, pos, force + Vector(math.Rand(fxmin, fxmax), math.Rand(fymin, fymax), math.Rand(fzmin, fzmax) * 1.5), ttl)
		
	end
	
	-- Regular number indicator.
	if not crit or critmode == CRIT_MODE.NONE or critmode == CRIT_MODE.DMG_ONLY or critmode == CRIT_MODE.CRIT_AND_DMG_EX or critmode >= CRIT_MODE.CRITICAL_AND_DMG_EX then
		
		local txt = ( showsign and tostring(-dmg) or tostring(math.abs(dmg)) )
		
		if crit and critmode == 1 then
			
			col = indicatorColors.crit
			
		else
			
			if bit.band(dmgtype, bit.bor(DMG_BURN, DMG_SLOWBURN, DMG_PLASMA)) != 0 then
				
				-- Fire damage.
				col = indicatorColors.fire
				
			elseif bit.band(dmgtype, bit.bor(DMG_BLAST, DMG_BLAST_SURFACE)) != 0 then
				
				-- Explosive damage.
				col = indicatorColors.expl
				
			elseif bit.band(dmgtype, bit.bor(DMG_ACID, DMG_POISON, DMG_RADIATION, DMG_NERVEGAS)) != 0 then
				
				-- Acidic damage.
				col = indicatorColors.acid
				
			elseif bit.band(dmgtype, bit.bor(DMG_DISSOLVE, DMG_ENERGYBEAM, DMG_SHOCK)) != 0 then
				
				-- Electrical damage.
				col = indicatorColors.elec
				
			end
			
		end
		
		spawnIndicator(txt, col, pos, force + Vector(math.Rand(fxmin, fxmax), math.Rand(fymin, fymax), math.Rand(fzmin, fzmax) * 1.5), ttl)
		
	end
	
end )


-- Update indicators.
hook.Add( "Tick", "hdn_updateInds", function()

	if not on then return end
	if debugger.enabled then debugger.ticktimer = SysTime() end
	
	local curtime = CurTime()
	local dt = curtime - lastcurtime
	lastcurtime = curtime
	
	if #indicators == 0 then return end
	
	local gravity = GetGlobalFloat("HDN_Gravity", 1.0) * 0.05
	
	-- Update hit texts.
	local ind
	for i=1, #indicators do
		ind = indicators[i]
		ind.life = ind.life - dt
	--  ind.vel.z = math.Min(ind.vel.z - 0.05, 2)
		ind.vel.z = ind.vel.z - gravity
		ind.pos = ind.pos + ind.vel
	end
	
	-- Check for and remove expired hit texts.
	local i = 1
	while i <= #indicators do
		if indicators[i].life < 0 then
			table.remove(indicators, i)
		else
			i = i + 1
		end
	end
	
	-- Update debugging info.
	if debugger.enabled then
		debugger.count = #indicators
		debugger.tickms = (SysTime() - debugger.ticktimer) * 1000
	end
	
end )


-- Render the 3D indicators.
hook.Add( "PostDrawTranslucentRenderables", "hdn_drawInds", function()
	
	if not on then return end
	if not initialized then return end
	if #indicators == 0 then return end
	if debugger.enabled then debugger.rendertimer = SysTime() end
	
	-- Indicators to always face the player.
	local observer = (LocalPlayer():GetViewEntity() or LocalPlayer())
	local ang = observer:EyeAngles()
	ang:RotateAroundAxis( ang:Forward(), 90 )
	ang:RotateAroundAxis( ang:Right(), 90 )
	ang = Angle( 0, ang.y, ang.r )
	
	local scale = GetGlobalFloat("HDN_Scale", 0.3)
	local alphamul = GetGlobalFloat("HDN_AlphaMul", 1) * 255
	local fanimation = ANIMATION_FUNC[GetGlobalInt("HDN_Animation", 0)]
	
	-- Is this even necessary to do anymore?
	local cam_Start3D2D        = cam.Start3D2D
	local cam_End3D2D          = cam.End3D2D
	local surface_SetTextColor = surface.SetTextColor
	local surface_SetTextPos   = surface.SetTextPos
	local surface_DrawText     = surface.DrawText
	
	-- Render above everything.
	local ignorez = GetGlobalBool("HDN_IgnoreZ", false)
	if ignorez then
		cam.IgnoreZ(true)
	end
	
	surface.SetFont("font_HDN_Inds")
	
	-- Render each indicator.
	local ind
	for i=1, #indicators do
		ind = indicators[i]
		cam_Start3D2D(ind.pos, ang, scale * ((fanimation ~= nil) and fanimation((CurTime() - ind.spawntime) / ind.ttl) or 1))
			surface_SetTextColor(ind.col.r, ind.col.g, ind.col.b, (ind.life / ind.ttl * alphamul))
			surface_SetTextPos(-ind.widthH, -ind.heightH)
			surface_DrawText(ind.text)
		cam_End3D2D()
	end
	
	-- Reset depth ignorance.
	if ignorez then
		cam.IgnoreZ(false)
	end
	
	if debugger.enabled then
		debugger.renderms = (SysTime() - debugger.rendertimer) * 1000
	end
	
end )


hook.Add( "HUDPaint", "hdn_debugHUD", function()
	
	if not on then return end
	if not debugger.enabled then return end
	
	local hudx, hudy = 10, 10
	
	local tickcol = color_white
	local rendercol = color_white
	
	for k,v in pairs({debugger.tickms, debugger.renderms}) do
		if v > 1.0 then
			if k == 1 then tickcol = Color(255,0,0,255)
			else rendercol = Color(255,0,0,255) end
		elseif v > 0.5 then
			if k == 1 then tickcol = Color(255,255,0,255)
			else rendercol = Color(255,255,0,255) end
		elseif v > 0.1 then
			if k == 1 then tickcol = Color(0,255,0,255)
			else rendercol = Color(0,255,0,255) end
		else
			if k == 1 then tickcol = Color(0,255,255,255)
			else rendercol = Color(0,255,255,255) end
		end
	end
	
	draw.RoundedBox(4, hudx, hudy, 128, 58, Color(0, 0, 0, 200))
	draw.Text({
		text = "HITNUMBERS - DEBUG",
		pos  = { hudx + 4, hudy + 4}
	})
	draw.Text({
		text = "Count " .. debugger.count,
		pos  = { hudx + 4, hudy + 20}
	})
	draw.Text({
		text  = "Tick " .. math.Round(debugger.tickms, 3) .. " ms",
		pos   = { hudx + 4, hudy + 30},
		color = tickcol
	})
	draw.Text({
		text  = "Render " .. math.Round(debugger.renderms, 3) .. " ms",
		pos   = { hudx + 4, hudy + 40},
		color = rendercol
	})
	
	debugger.tickms   = 0
	debugger.renderms = 0
	
end )


-- Spawn Menu settings for Sandbox gamemodes.
hook.Add("PopulateToolMenu", "hdn_spawnMenu", function()
	
	spawnmenu.AddToolMenuOption("Utilities", "Hit Numbers", "hdn_playerSpawnMenuSettings", "Player", "", "", populateSettingsPlayer)
	
end)

MsgN("-- Hit Numbers loaded --")