local indicators = {}
local lastcurtime = 0

// Damage indicator colours.
local dmg_cols = {
	gen =	Color(255, 230, 210),	/* Generic/Bullet damage */
	crit =	Color(255, 40,   40),	/* Critical hit */
	fire =	Color(255, 120,   0),	/* Fire damage */
	expl =	Color(240, 240,  50),	/* Explosion damage */
	acid =	Color(140, 255,  75),	/* Toxic damage */
	elec =	Color(100, 160, 255)	/* Electric/Shock damage */
}

// Font used for indicators.
surface.CreateFont( "font_HDN_Inds", {
	font 		= "coolvetica",
	size 		= 50,
	weight 		= 800,
	blursize 	= 0,
	scanlines 	= 0,
	antialias 	= false,
	underline 	= false,
	italic 		= false,
	strikeout 	= false,
	symbol 		= false,
	rotary 		= false,
	shadow 		= false,
	additive 	= false,
	outline 	= true
} )


// Client-side Hit Numbers show/hide concommand.
local on = true
concommand.Add( "hitnums_toggle", function()
	if not GetGlobalBool("HDN_AllowUserToggle") then
		MsgN("You do not have permission to show/hide Hit Numbers. Server convar 'sv_hitnums_allowusertoggle' is disabled.")
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


// Called when an indicator should be created for this player.
net.Receive( "net_HDN_createInd", function ()
	
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
	ind.ttl = 1.0
	ind.grav = 0.03*d
	ind.velx = math.Rand(-0.5, 0.5)*d + force.x
	ind.vely = math.Rand(-0.5, 0.5)*d + force.y
	ind.velz = math.Rand(1, 2)*d + force.z
	
	// Set color of indicator based on damage type (or critical hit).
	ind.col = (ind.crit and dmg_cols.crit or dmg_cols.gen)
	
	if not ind.crit then
		
		if bit.band(dmgtype, bit.bor(DMG_BURN, DMG_SLOWBURN, DMG_PLASMA)) != 0 then
			
			// Fire damage.
			ind.col = dmg_cols.fire
			
		elseif bit.band(dmgtype, bit.bor(DMG_BLAST, DMG_BLAST_SURFACE)) != 0 then
			
			// Explosive damage.
			ind.col = dmg_cols.expl
			
		elseif bit.band(dmgtype, bit.bor(DMG_ACID, DMG_POISON, DMG_RADIATION, DMG_NERVEGAS)) != 0 then
			
			// Acidic damage.
			ind.col = dmg_cols.acid
			
		elseif bit.band(dmgtype, bit.bor(DMG_DISSOLVE, DMG_ENERGYBEAM, DMG_SHOCK)) != 0 then
			
			// Electrical damage.
			ind.col = dmg_cols.elec
			
		end
		
	end
	
	// Add new indicator.
	table.insert(indicators, ind)
	
end )


// Update indicators.
hook.Add( "Tick", "hdn_updateInds", function ()

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
hook.Add( "PostDrawTranslucentRenderables", "hdn_drawInds", function ()
	
	if not on then return end
	if #indicators == 0 then return end
	
	local ang = LocalPlayer():EyeAngles()
	
	ang:RotateAroundAxis( ang:Forward(), 90 )
	ang:RotateAroundAxis( ang:Right(), 90 )
	
	local ignorez = GetGlobalBool("HDN_IgnoreZ", false)
	if ignorez then
		cam.IgnoreZ( true )
	end
	
	surface.SetFont("font_HDN_Inds")
	
	local col
	local txt
	local width, height
	for k,v in pairs(indicators) do
		
		col = v.col
		col.a = v.ttl * 255
		
		surface.SetTextColor(col)
		
		if v.crit then
			txt = "Critical " .. tostring(-v.dmg)
		else
			txt = tostring(-v.dmg)
		end
		
		txtWidth, txtHeight = surface.GetTextSize(txt)
		surface.SetTextPos(-txtWidth/2, -txtHeight/2)
		
		cam.Start3D2D( v.pos, Angle( 0, ang.y, ang.r ), 0.3 )
			surface.DrawText(txt)
			--draw.DrawText( txt, "font_HDN_Indicators", 0, 0, col, TEXT_ALIGN_CENTER )
		cam.End3D2D()
	end
	
	if ignorez then
		cam.IgnoreZ( false )
	end
	
end );
