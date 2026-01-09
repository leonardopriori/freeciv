-- Freeciv - Copyright (C) 2007 - The Freeciv Project
--   This program is free software; you can redistribute it and/or modify
--   it under the terms of the GNU General Public License as published by
--   the Free Software Foundation; either version 2, or (at your option)
--   any later version.
--
--   This program is distributed in the hope that it will be useful,
--   but WITHOUT ANY WARRANTY; without even the implied warranty of
--   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--   GNU General Public License for more details.

-- This file is for lua-functionality that is specific to a given
-- ruleset. When freeciv loads a ruleset, it also loads script
-- file called 'default.lua'. The one loaded if your ruleset
-- does not provide an override is default/default.lua.

--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
---
--- @script      Volcanoes are alive!
--- @description Dynamic volcanic activity system that manages transitions 
---              between dormant and active states, featuring randomized 
---              eruption intensities and automated city notifications.
--- @author      LeoPriori
--- @version     1.0 (freeciv v3.1+)
---
--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--- @table ___volcanoes_settings
---
--- Configuration for volcanic activity timing and probability.
---
--- Data Hierarchy:
---
--- volcano_names    <boolean>  Enables or disables the assignment of unique 
---                             names to each volcano entity.
--- activity_rarity  <number>   Frequency of activity checks (Turn + ID % 
---                             Value). Higher values increase the gap:
---                             1: Every turn | 10: Once every 10 turns.
--- eruption_chance  <number>   Percent probability of a dormant volcano 
---                             entering an active eruption state.
--- dormancy_chance  <number>   Percent probability of an active volcano 
---                             returning to a dormant state.
---
--- @type table<string, any>
--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
___volcanoes_settings = {
  volcano_names   = true,
  activity_rarity = 10,
  eruption_chance = 50,
  dormancy_chance = 50
}

--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--- @table ___volcanoes_dormant
---
--- List of terrains representing volcanoes in a quiet or inactive state.
---
--- Data Hierarchy:
---
--- name   <string>   Internal terrain name of the dormant volcano.
--- value  <boolean>  Always true for rapid look-up.
---
--- @type table<string, boolean>
--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
___volcanoes_dormant = {
	['Volcano'] = true,
}

--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--- @table ___volcanoes_active
---
--- List of terrains representing volcanoes currently in an eruption state.
---
--- Data Hierarchy:
---
--- name   <string>   Internal terrain name of the active volcano.
--- value  <boolean>  Always true for rapid look-up.
---
--- @type table<string, boolean>
--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
___volcanoes_active = {
	['Erupting_Volcano_A'] = true,
	['Erupting_Volcano_B'] = true,
}

--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--- @table ___volcanoes_msgs
---
--- Localization strings for volcanic events with dynamic placeholders.
---
--- Data Hierarchy:
---
--- key    <string>  Message identifier.
--- value  <string>  Translated string via _() function.
---
--- @type table<string, string>
--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
___volcanoes_msgs = {

	-- [1] City name
	-- [2] Volcano name
	-- [3] Tile position (x,y)
	volcano_awakened = 
	_("City %s alerts, the volcano %s has started erupting at %s!"),

	-- [1] City name
	-- [2] Volcano name
	-- [3] Tile position (x,y)
	volcano_sleeping = 
	_("City %s informs, the volcano %s at %s is back to sleep."),

	-- [1] City name
	-- [2] Tile position (x,y)
	volcano_awakened_no_name = 
	_("City %s alerts, a volcano has started erupting at %s!"),

	-- [1] City name
	-- [2] Tile position (x,y)
	volcano_sleeping_no_name = 
	_("City %s informs, the volcano at %s is back to sleep."),
	
}






--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--- @table __table_names
---
--- Internal table names used by the script for organized data structures.
---
--- Data Hierarchy:
---
--- key    <string>  Internal table identifier used by the engine. This key
---                  structure is fixed and must NOT be modified.
---
--- value  <string>  Name string used for identifying data structures in
---                  storage. Can be edited to avoid naming conflicts.
---
--- @type table<string, string>
--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__table_names = {

	--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	--- @name   volcanoes_awakened
	--- @desc   Stores volcanoes that started erupting this turn. 
	--- @data   Table (ID: Tile ID | Value: Unique Name)
	volcanoes_awakened = '___vlcns_t_volcanoes_awakened',

	--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	--- @name   volcanoes_sleeping
	--- @desc   Stores volcanoes that returned to dormancy this turn. 
	--- @data   Table (ID: Tile ID | Value: Unique Name)
	volcanoes_sleeping = '___vlcns_t_volcanoes_sleeping',

	--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	--- @name   volcanoes_names_list
	--- @desc   List of all volcano names (by luadata.txt)
	--- @data   Table (ID: Tile ID | Value: String Name)
	volcanoes_names_list = '___vlcns_t_volcanoes_names_list',

	--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	--- @name   volcanoes_used_names
	--- @desc   List of all volcano names (by luadata.txt)
	--- @data   Table (ID: Tile ID | Value: String Name)
	volcanoes_used_names = '___vlcns_t_volcanoes_used_names',

	--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	--- @name   volcanoes_names
	--- @desc   Persistent registry linking volcano IDs to their unique 
	---         randomized names.
	--- @data   Table (ID: Tile ID | Value: String Name)
	volcanoes_names = '___vlcns_t_volcanoes_names',
}

--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--- @table __var_names
---
--- Global variable identifiers used for persistent data storage keys.
---
--- Data Hierarchy:
---
--- key    <string>  Variable identifier used within the script logic.
---
--- value  <string>  The actual string key used in the global save data.
---                  Suffixes like '_' indicate a dynamic ID will be added.
---
--- @type table<string, string>
--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
__var_names = {

	--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	--- @name   all_volcanoes
	--- @desc   Stores a concatenated list of every volcano tile present on 
	---         the map.
	--- @format N/A
	--- @data   String (Concatenated Tile IDs)
	all_volcanoes = '___vlcns_s_all_volcanoes',

	--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	--- @name   volcano_activity
	--- @desc   Tracks the current state of a specific volcano (Dormant vs 
	---         Erupting).
	--- @format <tile_id>
	--- @data   String ("0" = Sleeping | "1" = Active)
	volcano_activity = '___vlcns_s_volcano_activity_',

	--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	--- @name   volcano_names
	--- @desc   Maps a specific volcano tile to its unique assigned name from 
	---         the name pool.
	--- @format <tile_id>
	--- @data   String (Unique Name)
	volcano_names = '___vlcns_s_volcano_names_',

	--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	--- @name   all_cities_volcanoes
	--- @desc   Maintains a list of all cities that have volcanic structures. 
	---         within their borders.
	--- @format <player_id>
	--- @data   String (Concatenated City IDs)
	all_cities_volcanoes = '___vlcns_s_all_cities_volcanoes_',

	--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	--- @name   city_volcanoes
	--- @desc   Stores which specific volcano tiles belong to a particular.
	---         city's territory.
	--- @format <city_id>
	--- @data   String (Concatenated Tile IDs)
	city_volcanoes = '___vlcns_s_city_volcanoes_',

	--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	--- @name   sum_all_volcanoes
	--- @desc   Stores the total number of tiles from the volcanoes.
	--- @format N/A
	--- @data   total
	sum_all_volcanoes = '___vlcns_s_sum_all_volcanoes_',
}
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local findCity = find.city
local findTile = find.tile
local findTerrain = find.terrain
local ipairs = ipairs
local mathFloor = math.floor
local notifyEvent = notify.event
local pairs = pairs
local random = random
local stringFormat = string.format
local stringGmatch = string.gmatch
local stringSub = string.sub
local tableConcat = table.concat
local tableInsert = table.insert
local toNumber = tonumber
local toString = tostring
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local function table_count(t)
	local n = 0
	for x,y in pairs(t) do n = n + 1 end
	return n
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local function lbl_tile_pos(tile)
	return mathFloor(tile.x) .. ',' .. mathFloor(tile.y) 
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local function split_string_ids(str)
	local tbl = {}
	if not str or str == '' then return tbl end
	for id_str in stringGmatch(str, '([^,]+)') do
		local id_num = toNumber(id_str)
		if id_num then tbl[id_num] = true end
	end
	return tbl
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local function split_string(var)
	local str = _G[var] or ''
	return split_string_ids(str)
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local function concatenate_string_ids(tbl)
	local list = {}
	for id, _ in pairs(tbl) do
		tableInsert(list, id)
	end
	if next(list) == nil then return nil end
	return tableConcat(list, ',')
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Adiciona um ID (fora de loops)
local function add_id_to_string(str, id)
	local tbl = split_string_ids(str) 
	tbl[id] = true
	local output = {}
	for k, _ in pairs(tbl) do tableInsert(output, k) end
	return tableConcat(output, ',')
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local function pick_unique_name()

	local tbl_names_list =  __table_names.volcanoes_names_list
	local tbl_used_names =  __table_names.volcanoes_used_names

	local pool = _G[tbl_names_list]
	if not pool then return "" end
	local total = #pool
	local max_attempts = 20 

	for _ = 1, max_attempts do
		local idx = random(1, total)
		local candidate = pool[idx]

		if not _G[tbl_used_names][candidate] then
			_G[tbl_used_names][candidate] = true
			return candidate
		end
	end

	for i = 1, total do
		local candidate = pool[i]
		if not _G[tbl_used_names][candidate] then
			_G[tbl_used_names][candidate] = true
			return candidate
		end
	end

	local name1 = pool[random(1, total)]
	local name2 = pool[random(1, total)]
	local combined = name1 .. "-" .. name2

	local final_name = combined
	local suffix = 1
	while _G[tbl_used_names][final_name] do
		final_name = combined .. " " .. suffix
		suffix = suffix + 1
	end

	_G[tbl_used_names][final_name] = true
	return final_name
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local function place_volcanoes()

	local pos = 0
	local var
	local volcanoes_list = {}
	for place in whole_map_iterate() do
		local place_id = mathFloor(place.id)
		local terr = place.terrain
		local tname = terr:rule_name()

		if ___volcanoes_dormant[tname] then
			volcanoes_list[place_id] = 0

		elseif ___volcanoes_active[tname] then
			volcanoes_list[place_id] = 1
		end
	end

	local lenght = table_count(volcanoes_list)
	var = __var_names.sum_all_volcanoes
	_G[var] = toString(lenght)  

	var = __var_names.all_volcanoes
	_G[var] = concatenate_string_ids(volcanoes_list)  

	local var_activity = __var_names.volcano_activity
	for volcano_id, active in pairs(volcanoes_list) do
		var = var_activity .. volcano_id 
		_G[var] = toString(active) 
	end

	if ___volcanoes_settings.volcano_names then 
		_G[__table_names.volcanoes_used_names] = {}
		local var_names = __var_names.volcano_names
		for volcano_id, active in pairs(volcanoes_list) do
			var =  var_names .. volcano_id 
			if not _G[var] then 
				local tile = findTile(volcano_id)
				if tile then 
					local name = pick_unique_name()
					_G[var] = name
					tile:set_label(name)
				end
			end
		end
	end
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local function notify_volcano_awakened(player, city, tile, volcano_name)
	local msg = ''
	if ___volcanoes_settings.volcano_names then 
		msg = stringFormat(___volcanoes_msgs.volcano_awakened,
			city.name, volcano_name, lbl_tile_pos(tile) ) 
	else		
		msg = stringFormat(___volcanoes_msgs.volcano_awakened_no_name,
			city.name, lbl_tile_pos(tile) ) 
	end
	notifyEvent(player, tile, E.CITY_DISORDER, msg)
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local function notify_volcano_sleeping(player, city, tile, volcano_name)
	local msg = ''
	if ___volcanoes_settings.volcano_names then 
		msg = stringFormat(___volcanoes_msgs.volcano_sleeping,
			city.name, volcano_name, lbl_tile_pos(tile) ) 
	else		
		msg = stringFormat(___volcanoes_msgs.volcano_sleeping_no_name,
			city.name, lbl_tile_pos(tile) ) 
	end
	notifyEvent(player, tile, E.CITY_NORMAL, msg)

	-- local v_name = ''
	-- local has_names = ___volcanoes_settings.volcano_names
	-- log.error('volcano_names sleeping => %s', has_names)
	-- -- if not ___volcanoes_settings.volcano_names then  
	-- -- 	v_name = volcano_name
	-- -- end
	-- notifyEvent(player, tile, E.CITY_NORMAL,
	-- 	stringFormat(___volcanoes_msgs.volcano_sleeping, 
	-- 		city.name, v_name, lbl_tile_pos(tile) ) )
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function city_built_callback(city)
	local cityTile = city.tile 
	local city_id = mathFloor(city.id)
	local var_volcano_activity = __var_names.volcano_activity
	local var
	local val
	local volcanoes_list = {}


	local has_any = false
	for next_tile in cityTile:circle_iterate(city:map_sq_radius()) do
		local tile_id = mathFloor(next_tile.id)
		var = var_volcano_activity .. tile_id 
		val = _G[var]
		if val then 
			has_any = true
			volcanoes_list[next_tile] = true
		end
	end
	if has_any then 

		local var = __var_names.city_volcanoes .. city_id
		local tiles = split_string(var)
		for volcano, active in pairs(volcanoes_list) do
			local volcano_id = mathFloor(volcano.id)
			tiles[volcano_id] = true
		end
		_G[var] = concatenate_string_ids(tiles)

		local player = city.owner
		local player_id = mathFloor(player.id)
		var = __var_names.all_cities_volcanoes .. player_id
		val = _G[var]
		_G[var] = add_id_to_string(val, city_id)
	end
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local function get_random_terrain_volcano(tbl)
	local pool = {}
	for name, _ in pairs(tbl) do pool[#pool + 1] = name end
	if #pool == 0 then return '' end
	return pool[random(1, #pool)]
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local function volcano_change_terrain(tile, tbl)
	local nm_terrain = get_random_terrain_volcano(tbl)
	local terrain = findTerrain(nm_terrain)
	if terrain then 
		edit.change_terrain(tile, terrain)
	end
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local function volcanoes_activity()
	local turn = game.current_turn()
	local var_list = __var_names.all_volcanoes
	local volcanoes_list = split_string(var_list)
	if not volcanoes_list then return end

	local has_names = ___volcanoes_settings.volcano_names
	local activity_rarity = ___volcanoes_settings.activity_rarity
	local eruption_chance = ___volcanoes_settings.eruption_chance
	local dormancy_chance = ___volcanoes_settings.dormancy_chance
	local var_activity = __var_names.volcano_activity
	local var_names    = __var_names.volcano_names
	local volcanoes_awakened = {}
	local volcanoes_sleeping = {}

	for volcano_id, _ in pairs(volcanoes_list) do
		local tile = findTile(volcano_id)
		if tile then 
			if (turn + toNumber(volcano_id)) % activity_rarity == 0 then
				local v_var = var_activity .. volcano_id
				local activity = toNumber(_G[v_var] or '0')
				local v_name = has_names and 
					(_G[var_names .. volcano_id] or 'Unknown') or true --toString(volcano_id)

				if activity == 0 then 
					if random(1, 100) <= eruption_chance then
						_G[v_var] = '1'
						volcanoes_awakened[volcano_id] = v_name
						volcano_change_terrain(tile, ___volcanoes_active)           
					end
				elseif activity == 1 then 
					if random(1, 100) <= dormancy_chance then
						_G[v_var] = '0'
						volcanoes_sleeping[volcano_id] = v_name
						volcano_change_terrain(tile, ___volcanoes_dormant)
					end
				end
			end
		end
	end

	_G[__table_names.volcanoes_awakened] = volcanoes_awakened
	_G[__table_names.volcanoes_sleeping] = volcanoes_sleeping

end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local function get_label_format_report(number, string_base)
	if number > 0 then
		local txt 
		if number == 1 then 
			txt = string_base.singular
		elseif number > 1 then
			txt = string_base.plural
		end
		return stringFormat(txt, number)
	end
	return string_base
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local function notify_cities(player)
	local player_id = mathFloor(player.id)
	local list_awakened = _G[__table_names.volcanoes_awakened]
	local list_sleeping = _G[__table_names.volcanoes_sleeping]
	local var_city_volcanoes = __var_names.city_volcanoes
	local var = __var_names.all_cities_volcanoes .. player_id
	local cities = split_string(var)
	if cities then 
		local tiles_ids
		for city_id, _ in pairs(cities) do
			local city = findCity(player, city_id)
			if city then 
				var =  var_city_volcanoes .. city_id
				tiles_ids = split_string(var)
				if tiles_ids then         
					for tile_id, _ in pairs(tiles_ids) do
						if list_awakened and list_awakened[tile_id] then 
							local tile = findTile(tile_id)
							if tile then 
								notify_volcano_awakened(player, 
									city, tile,
									list_awakened[tile_id])
							end       
						end
						if list_sleeping and list_sleeping[tile_id] then 
							local tile = findTile(tile_id)
							if tile then 
								notify_volcano_sleeping(player, 
									city, tile,
									list_sleeping[tile_id])
							end       
						end
					end
				end
			end
		end
	end
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local function get_all_volcano_names()
	local names = {}
	for a = 1, 435 do 
		local name = luadata.get_str(string.format("volcano_%d.name", a))
		if name then 
			names[#names+1] = name    
		end
	end
	_G[__table_names.volcanoes_names_list] = names

end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function turn_callback(turn, year)
	if turn > 1 then 
		volcanoes_activity()
	end
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function map_generated_callback()
	get_all_volcano_names()
	place_volcanoes()
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function player_phase_begin_callback(player)
	if player:is_human() then 
		notify_cities(player)
	end
end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
signal.connect('turn_begin', 'turn_callback')
signal.connect('map_generated', 'map_generated_callback')
signal.connect('player_phase_begin', 'player_phase_begin_callback')
signal.connect('city_built', 'city_built_callback')
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
