local indicators = {}
local initialized = false
local lastcurtime = 0


// Set up hit numbers.
net.Receive( "net_HDN_initialize", function()
	
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
	
	initialized = true
	
end )


// Build colour table from server-set colours.
local function buildColourTable()
	
	local dmgCols = {}
	local col
	
	col = GetGlobalInt("HDN_Col_Gen", 16770770)
	dmgCols.gen = Color(bit.band(bit.rshift(col, 16), 255), bit.band(bit.rshift(col, 8), 255), bit.band(col, 255))
	
	col = GetGlobalInt("HDN_Col_Crit", 16721960)
	dmgCols.crit = Color(bit.band(bit.rshift(col, 16), 255), bit.band(bit.rshift(col, 8), 255), bit.band(col, 255))
	
	col = GetGlobalInt("HDN_Col_Fire", 16742400)
	dmgCols.fire = Color(bit.band(bit.rshift(col, 16), 255), bit.band(bit.rshift(col, 8), 255), bit.band(col, 255))
	
	col = GetGlobalInt("HDN_Col_Expl", 15790130)
	dmgCols.expl = Color(bit.band(bit.rshift(col, 16), 255), bit.band(bit.rshift(col, 8), 255), bit.band(col, 255))
	
	col = GetGlobalInt("HDN_Col_Acid", 9240395)
	dmgCols.acid = Color(bit.band(bit.rshift(col, 16), 255), bit.band(bit.rshift(col, 8), 255), bit.band(col, 255))
	
	col = GetGlobalInt("HDN_Col_Elec", 6594815)
	dmgCols.elec = Color(bit.band(bit.rshift(col, 16), 255), bit.band(bit.rshift(col, 8), 255), bit.band(col, 255))
	
	return dmgCols
	
end


local function spawnIndicator(text, col, pos, vel, ttl)
	
	if not initialized then return end
	
	local ind = {}
	
	ind.text = text
	ind.pos = Vector(pos.x, pos.y, pos.z)
	ind.vel = Vector(vel.x, vel.y, vel.z)
	ind.col = Color(col.r, col.g, col.b)
	
	ind.ttl = ttl
	ind.life = ttl
	
	surface.SetFont("font_HDN_Inds")
	local w, h = surface.GetTextSize(text)
	
	ind.widthH = w/2
	ind.heightH = h/2
	
	table.insert(indicators, ind)
	
end


// Client-side Hit Numbers show/hide concommand.
local on = true
concommand.Add( "hitnums_toggle", function()
	
	if not GetGlobalBool("HDN_AllowUserToggle") then
		MsgN("You do not have permission to hide the Hit Numbers indicators. (Server convar 'sv_hitnums_allowusertoggle' is disabled)")
		return
	end
	
	on = not on
	
	Msg("Damage indicators ")
	if on then
		MsgN("enabled")
	else
		MsgN("disabled")
		table.Empty(indicators)
	end
	
end )


net.Receive( "net_HDN_forceToggleOn", function()
	
	on = true
	
end )


// Called when an indicator should be created for this player.
net.Receive( "net_HDN_createInd", function()
	
	if not on then return end
	
	local ind = {}
	
	// Get damage type and amount.
	local dmg = net.ReadFloat()
	local dmgtype = net.ReadUInt(32)
	
	if dmg < 1 then dmg = math.Round(dmg, 3) 
	else dmg = math.floor(dmg) end
	
	// Get "critical hit" bit.
	local crit = (net.ReadBit() ~= 0)
	
	// Retreive position and force of the damage.
	local pos = net.ReadVector()
	local force = net.ReadVector()
	
	// Set color of indicator based on damage type (or critical hit).
	local dmgCols = buildColourTable()
	local col = dmgCols.gen
	
	local ttl = GetGlobalFloat("HDN_TTL", 1.0)
	local showsign = GetGlobalBool("HDN_ShowSign", true)
	local critmode = GetGlobalInt("HDN_CritMode", 5) /* See "Critical indicator mode" in sv_hitdamagenumbers.lua */
	
	if crit and critmode >= 2 then
		
		local txt
		
		if critmode == 2 or critmode == 6 then
			
			txt = "Crit!"
			
		elseif critmode == 3 or critmode == 7 then
			
			txt = "Critical!"
			
		elseif critmode == 4 then
			
			txt = "Crit " .. ( showsign and tostring(-dmg) or tostring(math.abs(dmg)) )
			
		elseif critmode == 5 then
			
			txt = "Critical " .. ( showsign and tostring(-dmg) or tostring(math.abs(dmg)) )
			
		end
		
		spawnIndicator(txt, dmgCols.crit, pos, force + Vector(math.Rand(-0.5, 0.5), math.Rand(-0.5, 0.5), math.Rand(1.1, 1.4)), ttl)
		
	end
	
	if not crit or critmode == 0 or critmode == 1 or critmode == 6 or critmode == 7 then
		
		local txt = ( showsign and tostring(-dmg) or tostring(math.abs(dmg)) )
		
		if crit and critmode == 1 then
			
			col = dmgCols.crit
			
		else
			
			if bit.band(dmgtype, bit.bor(DMG_BURN, DMG_SLOWBURN, DMG_PLASMA)) != 0 then
				
				// Fire damage.
				col = dmgCols.fire
				
			elseif bit.band(dmgtype, bit.bor(DMG_BLAST, DMG_BLAST_SURFACE)) != 0 then
				
				// Explosive damage.
				col = dmgCols.expl
				
			elseif bit.band(dmgtype, bit.bor(DMG_ACID, DMG_POISON, DMG_RADIATION, DMG_NERVEGAS)) != 0 then
				
				// Acidic damage.
				col = dmgCols.acid
				
			elseif bit.band(dmgtype, bit.bor(DMG_DISSOLVE, DMG_ENERGYBEAM, DMG_SHOCK)) != 0 then
				
				// Electrical damage.
				col = dmgCols.elec
				
			end
			
		end
		
		spawnIndicator(txt, col, pos, force + Vector(math.Rand(-0.5, 0.5), math.Rand(-0.5, 0.5), math.Rand(0.75, 1.0)), ttl)
		
	end
	
end )


// Update indicators.
hook.Add( "Tick", "hdn_updateInds", function()

	if not on then return end
	
	local curtime = CurTime()
	local dt = curtime - lastcurtime
	lastcurtime = curtime
	
	// Update hit texts.
	for _, ind in pairs(indicators) do
		
		ind.life = ind.life - dt
	
		--ind.vel.z = math.Min(ind.vel.z - 0.05, 2)
		ind.vel.z = ind.vel.z - 0.05
		
		ind.pos.x = ind.pos.x + ind.vel.x
		ind.pos.y = ind.pos.y + ind.vel.y
		ind.pos.z = ind.pos.z + ind.vel.z
		
	end
	
	// Check for and remove expired hit texts.
	local i = 1
	while i <= #indicators do
		if indicators[i].life < 0 then
			table.remove(indicators, i)
		else
			i = i + 1
		end
	end
	
end )


-- Render the 3D indicators.
hook.Add( "PostDrawTranslucentRenderables", "hdn_drawInds", function()
	
	if not on then return end
	if not initialized then return end
	if #indicators == 0 then return end
	
	local observer = ( LocalPlayer():GetViewEntity() or LocalPlayer() )
	local ang = observer:EyeAngles()
	ang:RotateAroundAxis( ang:Forward(), 90 )
	ang:RotateAroundAxis( ang:Right(), 90 )
	ang = Angle( 0, ang.y, ang.r )
	
	local ignorez = GetGlobalBool("HDN_IgnoreZ", false)
	if ignorez then
		cam.IgnoreZ( true )
	end
	
	local scale = GetGlobalFloat("HDN_Scale", 0.3)
	local alphamul = GetGlobalFloat("HDN_AlphaMul", 1) * 255
	
	surface.SetFont("font_HDN_Inds")
	
	for _, ind in pairs(indicators) do
		
		ind.col.a = (ind.life / ind.ttl) * alphamul
		surface.SetTextColor(ind.col)
		
		surface.SetTextPos(-ind.widthH, -ind.heightH)
		
		cam.Start3D2D(ind.pos, ang, scale)
			surface.DrawText(ind.text)
		cam.End3D2D()
	end
	
	if ignorez then
		cam.IgnoreZ( false )
	end
	
end );
