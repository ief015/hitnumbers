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
	
	col = GetGlobalVar("HDN_Col_Gen", 16770770)
	dmgCols.gen = Color(bit.band(bit.rshift(col, 16), 255), bit.band(bit.rshift(col, 8), 255), bit.band(col, 255))
	
	col = GetGlobalVar("HDN_Col_Crit", 16721960)
	dmgCols.crit = Color(bit.band(bit.rshift(col, 16), 255), bit.band(bit.rshift(col, 8), 255), bit.band(col, 255))
	
	col = GetGlobalVar("HDN_Col_Fire", 16742400)
	dmgCols.fire = Color(bit.band(bit.rshift(col, 16), 255), bit.band(bit.rshift(col, 8), 255), bit.band(col, 255))
	
	col = GetGlobalVar("HDN_Col_Expl", 15790130)
	dmgCols.expl = Color(bit.band(bit.rshift(col, 16), 255), bit.band(bit.rshift(col, 8), 255), bit.band(col, 255))
	
	col = GetGlobalVar("HDN_Col_Acid", 9240395)
	dmgCols.acid = Color(bit.band(bit.rshift(col, 16), 255), bit.band(bit.rshift(col, 8), 255), bit.band(col, 255))
	
	col = GetGlobalVar("HDN_Col_Elec", 6594815)
	dmgCols.elec = Color(bit.band(bit.rshift(col, 16), 255), bit.band(bit.rshift(col, 8), 255), bit.band(col, 255))
	
	return dmgCols
	
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
	local lply = LocalPlayer()
	
	if not lply:IsValid() then return end
	
	local ind = {}
	
	// Get damage type and amount.
	local dmg = net.ReadFloat()
	local dmgtype = net.ReadUInt(32)
	
	if dmg < 1 then ind.dmg = math.Round(dmg, 3) 
	else ind.dmg = math.floor(dmg) end
	
	// Get "critical hit" bit.
	ind.crit = (net.ReadBit()==1)
	
	// Retreive position and force of the damage.
	ind.pos = net.ReadVector()
	local force = net.ReadVector()
	
	local d = ind.pos:Distance(lply:GetPos())/200
	d = math.Clamp(d, 0, 2)
	
	// Set properties of this indicator.
	ind.ttl = GetGlobalFloat("HDN_TTL", 1.0)
	ind.grav = 0.03*d
	ind.velx = math.Rand(-0.5, 0.5)*d + force.x
	ind.vely = math.Rand(-0.5, 0.5)*d + force.y
	ind.velz = math.Rand(1, 2)*d + force.z
	
	// Set color of indicator based on damage type (or critical hit).
	local dmgCols = buildColourTable()
	
	ind.col = (ind.crit and dmgCols.crit or dmgCols.gen)
	
	if not ind.crit then
		
		if bit.band(dmgtype, bit.bor(DMG_BURN, DMG_SLOWBURN, DMG_PLASMA)) != 0 then
			
			// Fire damage.
			ind.col = dmgCols.fire
			
		elseif bit.band(dmgtype, bit.bor(DMG_BLAST, DMG_BLAST_SURFACE)) != 0 then
			
			// Explosive damage.
			ind.col = dmgCols.expl
			
		elseif bit.band(dmgtype, bit.bor(DMG_ACID, DMG_POISON, DMG_RADIATION, DMG_NERVEGAS)) != 0 then
			
			// Acidic damage.
			ind.col = dmgCols.acid
			
		elseif bit.band(dmgtype, bit.bor(DMG_DISSOLVE, DMG_ENERGYBEAM, DMG_SHOCK)) != 0 then
			
			// Electrical damage.
			ind.col = dmgCols.elec
			
		end
		
	end
	
	// Add new indicator.
	table.insert(indicators, ind)
	
end )


// Update indicators.
hook.Add( "Tick", "hdn_updateInds", function()

	if not on then return end
	
	local curtime = CurTime()
	local dt = curtime - lastcurtime
	lastcurtime = curtime
	
	// Update hit texts.
	for k,v in pairs(indicators) do
		
		v.ttl = v.ttl - dt
		
		v.velz = math.Min(v.velz - v.grav, 1)
		
		v.pos.x = v.pos.x + v.velx
		v.pos.y = v.pos.y + v.vely
		v.pos.z = v.pos.z + v.velz
		
	end
	
	// Check for and remove expired hit texts.
	local i = 1
	while i <= #indicators do
		
		if indicators[i].ttl < 0 then
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
	
	local ang = LocalPlayer():EyeAngles()
	
	ang:RotateAroundAxis( ang:Forward(), 90 )
	ang:RotateAroundAxis( ang:Right(), 90 )
	
	local ignorez = GetGlobalBool("HDN_IgnoreZ", false)
	if ignorez then
		cam.IgnoreZ( true )
	end
	
	local scale = GetGlobalFloat("HDN_Scale", 0.3)
	local showsign = GetGlobalBool("HDN_ShowSign", true)
	local ttl = GetGlobalFloat("HDN_TTL", 1.0)
	
	surface.SetFont("font_HDN_Inds")
	
	local col
	local txt
	local width, height
	for _, ind in pairs(indicators) do
		
		col = ind.col
		col.a = (ind.ttl / ttl) * 255
		
		surface.SetTextColor(col)
		
		if ind.crit then
			txt = "Critical " .. (showsign and tostring(-ind.dmg) or tostring(math.abs(ind.dmg)))
		else
			txt = (showsign and tostring(-ind.dmg) or tostring(math.abs(ind.dmg)))
		end
		
		txtWidth, txtHeight = surface.GetTextSize(txt)
		surface.SetTextPos(-txtWidth/2, -txtHeight/2)
		
		cam.Start3D2D(ind.pos, Angle( 0, ang.y, ang.r ), scale)
			surface.DrawText(txt)
			--draw.DrawText( txt, "font_HDN_Indicators", 0, 0, col, TEXT_ALIGN_CENTER )
		cam.End3D2D()
	end
	
	if ignorez then
		cam.IgnoreZ( false )
	end
	
end );
