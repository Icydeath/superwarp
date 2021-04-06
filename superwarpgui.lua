--[[ SUPERWARP GUI v0.1 ]]

--------------------------
------ GUI SETTINGS ------
--------------------------
show_gui = true -- set this to false and reload superwarp if you don't want to use it anymore :(
gui_x = 1500 -- horizontal direction (left to right)
gui_y = 20 -- vertical direction (top to bottom)
is_all = true -- default state for the 'all' command.
log_warp_cmd = true -- set to true to log the command the gui created.
combobox_background = true -- set to false to hide the combobox backgrounds
show_friendly_warptype_names = false -- setting to true will list the friendly names instead of the warp type aliases.
--------------------------

require('Modes')
require('GUI')

shortname_to_dataname = {
	['hp'] = 'homepoints',
	['sg'] = 'guides',
	['vw'] = 'voidwatch',
	['po'] = 'portals',
	['wp'] = 'waypoints',
	['pwp'] = 'protowaypoints',
	['ew'] = 'escha',
	['ab'] = 'abyssea',
	['un'] = 'unity'
}

function send_warp_command(wt, zone, loc)
	if wt and zone then
		if wt:startswith(' ') or wt:startswith('[') then return end
		if show_friendly_warptype_names then
			for sn, ln in pairs(shortname_to_dataname) do
				if ln == wt then
					wt = sn
					break
				end
			end
		end
		
		if loc then
			if loc:startswith('Cavernous') or loc:startswith('Enigmatic') then 
				loc = ''
			elseif loc:startswith('Mog') then 
				loc = 'mh'
			elseif loc:startswith('Auction') then 
				loc = 'ah' 
			end
		end
		
		local cmd = wt..(is_all and ' all ' or ' ')..zone..(loc and ' '..loc or '')
		if log_warp_cmd then log(cmd) end
		windower.send_command(cmd)
	end
end

function draw_cb(cb)
	cb:draw()
	if not combobox_background then
		windower.prim.set_visibility(tostring(cb)..' mid', false)
	end
end

if show_gui then
	-- Setup 'All' toggle
	all_toggle_label = PassiveText({
		x = gui_x + 4,
		y = gui_y + 10,
		text = 'ALL',
	})
	all_toggle_label:draw()

	all_toggle = ToggleButton{
		x = gui_x,
		y = gui_y - 7,
		var = 'is_all', -- variable to track the state of the toggle
		iconUp = 'uncheck.png',
		iconDown = 'check.png',
		command = function()  -- call a function here to perform specific tasks when turned on and off.
			--settings.gui_default_all = is_all
			--settings:save('all')
			--log('gui_default_all' .. settings.gui_default_all)
		end
	}
	all_toggle:draw()

	-- get all sub commands
	sub_command_keys = S{}
	for k,dataset in pairs(maps) do
		if dataset.sub_commands then
			for subkey,_ in pairs(dataset.sub_commands) do
				sub_command_keys:add(subkey)
			end
		end
	end
	
	-- Setup warp type combobox
	warp_types = L{['description'] = 'Types', (show_friendly_warptype_names and '       [ w a r p ]' or '[ w a r p ]')}
	for i, sn in pairs(warp_list) do
		local wt = show_friendly_warptype_names and shortname_to_dataname[sn] or sn
		warp_types:append(wt)
	end
	type_dropdown_options = { M(warp_types) }
	type_dropdown = Combobox {
		x = gui_x + 41,
		y = gui_y,
		size = 10,
		width = show_friendly_warptype_names and 121 or 66,
		var = type_dropdown_options[1],
		callback = (
			function(selected)
				if zone_dropdown then
					zone_dropdown:undraw()
					zone_dropdown = nil
					if loc_dropdown then
						loc_dropdown:undraw()
						loc_dropdown = nil
					end
				end
				
				if not selected or selected:startswith(' ') or selected:startswith('[') then
					return
				end
				
				dataname = shortname_to_dataname[selected] or selected
				if not dataname then return end
				
				local list = L{['description'] = 'Zones', '                 [ z o n e ]'}
				if maps[dataname].sub_commands then
					for k,v in pairs(maps[dataname].sub_commands) do
						list:append(k)
					end
				end
				if maps[dataname].warpdata then
					for k,v in pairs(maps[dataname].warpdata) do
						list:append(k)
					end
				end
				
				zone_dropdown_options = { M(table.sort(list)) }
				zone_dropdown = Combobox {
					x = gui_x + (show_friendly_warptype_names and 161 or 107),
					y = gui_y,
					size = 10,
					width = 200,
					var = zone_dropdown_options[1],
					callback = (
						function(zone_selected)
							if loc_dropdown then
								loc_dropdown:undraw()
								loc_dropdown = nil
							end
							if not zone_selected then return end
							--print(table.tovstring(maps[dataname].warpdata[zone_selected]))
							if sub_command_keys:contains(zone_selected) 
								or (maps[dataname].warpdata[zone_selected] and maps[dataname].warpdata[zone_selected].index)
								or T(maps[dataname].warpdata[zone_selected]):length() == 1 then
									send_warp_command(type_dropdown._track._state, zone_selected)
								return
							end
							
							local list = L{['description'] = 'Locations', '   [ l o c a t i o n ] '}
							for key,data in pairs(maps[dataname].warpdata[zone_selected]) do
								list:append(key)
							end
														
							loc_dropdown_options = { M(list) }
							loc_dropdown = Combobox {
								x = gui_x + (show_friendly_warptype_names and 361 or 307),
								y = gui_y,
								size = 10,
								width = 120,
								var = loc_dropdown_options[1],
								callback = (
									function(loc_selected)
										if loc_selected:startswith(' ') then return end
										send_warp_command(type_dropdown._track._state, zone_dropdown._track._state, loc_selected)
									end
								)
							} -- end of loc_dropdown
							draw_cb(loc_dropdown)
						end
					)
				} -- end of zone_dropdown
				draw_cb(zone_dropdown)
			end
		)
	} -- end of type_dropdown
	draw_cb(type_dropdown)
end