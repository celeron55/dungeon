-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--
--! @file environment.lua
--! @brief component for environment related functions
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--
--! @defgroup environment Environment subcomponent
--! @brief Environment check functions used by different subcomponents
--! @ingroup framework_int
--! @{
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

environment = {}

--! @brief list of known environments
--! @memberof environment
environment_list = {}



-------------------------------------------------------------------------------
-- name: get_suitable_pos_same_level(pos_raw,maxsearcharea,entity)
--
--! @brief find a position suitable around a specific position
--! @ingroup environment
--
--! @param pos_raw position to look at
--! @param maxsearcharea max range to look for suitable position
--! @param entity mob to look for position
--! @param accept_possible return position thats possible only too
--! @return {x,y,z} position found or nil
-------------------------------------------------------------------------------
function environment.get_suitable_pos_same_level(pos_raw,maxsearcharea,entity,accept_possible)
    dbg_mobf.movement_lvl3("MOBF: --> get_suitable_pos_same_level " 
    	.. printpos(pos_raw))
	local pos = mobf_round_pos(pos_raw)

	dbg_mobf.movement_lvl1("MOBF: Starting pos is "..printpos(pos)
		.." max search area is "..maxsearcharea)

	local e1 = "|"
	local e2 = "|"
	local e3 = "|"
	local e4 = "|"
	
	local possible_targets = {}

	--search next position on solid ground
	for search=1, maxsearcharea,1 do
		--TODO randomize search order

		--find along edge 1
		for current=-search,search,1 do
			local pos_tocheck = { x= pos.x + current,y=pos.y,z=pos.z -search}		
			local pos_state = environment.pos_is_ok(pos_tocheck,entity)

			dbg_mobf.movement_lvl1("MOBF: state of "..printpos(pos_tocheck).." is " 
				.. pos_state)

			if pos_state == "ok" then
				dbg_mobf.movement_lvl1("found new pos")
				table.insert(possible_targets, pos_tocheck)
			elseif pos_state == "possible_surface" and
					accept_possible then
				table.insert(possible_targets, pos_tocheck)
--			elseif pos_state == "collision_jumpabe" then
--				dbg_mobf.movement_lvl1("found new pos above")
--				return {x=pos_tocheck.x,y=pos_tocheck.y+1,z=pos_tocheck.z}
			else
				e1 = e1..pos_state.."|"
			end			
		end

		--find along edge 2
		for current=-(search-1),(search-1),1 do
			local pos_tocheck = { x= pos.x + search,y=pos.y,z=pos.z + current}		
			local pos_state = environment.pos_is_ok(pos_tocheck,entity)
			
			dbg_mobf.movement_lvl1("MOBF: state of "..printpos(pos_tocheck).." is "
				.. pos_state)

			if pos_state == "ok" then
				dbg_mobf.movement_lvl1("found new pos")
				table.insert(possible_targets, pos_tocheck)
			elseif pos_state == "possible_surface" and
					accept_possible then
				table.insert(possible_targets, pos_tocheck)
			else
				e2 = e2..pos_state.."|"
			end			
		end

		--find along edge 3

		for current=search,-search,-1 do
			local pos_tocheck = { x= pos.x + current,y=pos.y,z=pos.z + search}		
			local pos_state = environment.pos_is_ok(pos_tocheck,entity)

			dbg_mobf.movement_lvl1("MOBF: state of "..printpos(pos_tocheck).." is "
				.. pos_state)

			if pos_state == "ok" then
				dbg_mobf.movement_lvl1("found new pos")
				table.insert(possible_targets, pos_tocheck)
			elseif pos_state == "possible_surface" and
					accept_possible then
				table.insert(possible_targets, pos_tocheck)
			else
				e3 = e3..pos_state.."|"
			end			
		end

		--find along edge 4
		for current=(search-1),-(search-1),-1 do
			local pos_tocheck = { x= pos.x -search,y=pos.y,z=pos.z + current}		
			local pos_state = environment.pos_is_ok(pos,entity)

			dbg_mobf.movement_lvl1("MOBF: state of "..printpos(pos_tocheck).." is "
				.. pos_state)

			if pos_state == "ok" then
				dbg_mobf.movement_lvl1("found new pos")
				table.insert(possible_targets, pos_tocheck)
			elseif pos_state == "possible_surface" and
					accept_possible then
				table.insert(possible_targets, pos_tocheck)
			else
				e4 = e4..pos_state.."|"
			end			
		end
	end

--	print("MOBF: Bug !!! didn't find a suitable position to place mob")
--	print("Surrounding of " .. printpos(pos_raw) .. "was:")
--	print(e1)
--	print("          " .. e2)
--	print(e4)
--	print(e3)

	if #possible_targets > 0 then
		local i = math.random(1, #possible_targets)
		return possible_targets[i]
	end

	return nil
end

-------------------------------------------------------------------------------
-- name: is_media_element(nodename,environment)
--
--! @brief check if nodename is in environment
--! @ingroup environment
--
--! @param nodename name to check
--! @param media environment of mob
--! @return true/false
------------------------------------------------------------------------------
function environment.is_media_element( nodename, media )

	--security check
	if media == false then
	    mobf_bug_warning(LOGLEVEL_ERROR,"MOBF: BUG!!!! no environment specified!")
		return false
	end
	
	for i,v in ipairs(media) do
		if v == nodename then
			return true
		end
	end
	
	dbg_mobf.environment_lvl2("MOBF: " .. nodename .. " is not within environment list:")
	
	for i,v in ipairs(media) do
		dbg_mobf.environment_lvl3("MOBF: \t" .. v)
	end
	
	return false
end

-------------------------------------------------------------------------------
-- name: get_absolute_min_max_pos(env, pos)
--
--! @brief check if nodename is in environment
--! @ingroup environment
--
--! @param env environment mob should be
--! @param pos position it is currently
--! @return { minpos,maxpos }
------------------------------------------------------------------------------
function environment.get_absolute_min_max_pos(env,pos)
	
	local node = minetest.env:get_node(pos)

	--if is not within environment it should be return current position
	--as min max
	if environment.is_media_element(node.name,env.media) == false then
		return pos.y,pos.y
	end
	
	local min_y = env.min_height_above_ground
	local max_y = env.max_height_above_ground
	
	
	--a fully generic check isn't possible here so we need to use media
	--specific ways ... it's ugly but works
	if node.name == "air" then
		min_y = min_y + ( pos.y - mobf_surface_distance(pos))
		max_y = max_y + ( pos.y - mobf_surface_distance(pos))
	end
	
	if node.name == "default:water" or
		node.name == "defailt:water_flowing" then
		-- water mobs do use min/max directly
	end
	
	if node.name == "default:lava" or 
		node.name == "default:lava_flowing" then
		--TODO e.g. lava fish
		--not implemented by now
	end

	return min_y,max_y
end


-------------------------------------------------------------------------------
-- name: is_jumpable_surface(name)
--
--! @brief check if name is a surface an mob may jump onto
--! @ingroup environment
--
--! @param name name to check
--! @return true/false
-------------------------------------------------------------------------------
function environment.is_jumpable_surface(name)

	
	if 	name == "default:dirt" or
		name == "default:dirt_with_grass" or
		name == "default:stone" or
		name == "default:sand" or
		name == "default:clay"
		then
		return true
	end

	dbg_mobf.environment_lvl1("MOBF: is "..name.." a jumpable surface?")
	return false
end

-------------------------------------------------------------------------------
-- name: checksurfacek(pos,surfaces)
--
--! @brief check if a position is suitable for an mob
--! @ingroup environment
--
--! @param pos position to check
--! @param surface surfaces valid
--! @return true on valid surface false if not
-------------------------------------------------------------------------------
function environment.checksurface(pos,surface)
	
	--if no surfaces are specified any surface is treated as ok
	if surface == nil then
		return "ok"
	end
	
	local pos_below = {x=pos.x,y=pos.y-1,z=pos.z}
	
	local node_below = minetest.env:get_node(pos_below)
	
	
	if node_below == nil then
		return "ok"
	end
	
	for i,v in ipairs(surface.good) do
		if node_below.name == v then
			return "ok"
		end
	end
	
	if surface.possible ~= nil then	
		for i,v in ipairs(surface.possible) do
			if node_below.name == v then
				return "possible_surface"
			end
		end
	end
	
	return "wrong_surface"

end

-------------------------------------------------------------------------------
-- name: get_min_max_ground_dist(entity)
--
--! @brief calculate absolute minimum and maximum height for a mob
--! @ingroup environment
--
--! @param entity mob to check
--! @return min y val,max y val
-------------------------------------------------------------------------------
function environment.get_min_max_ground_dist(entity)
	local min_ground_distance   = 0
	local max_ground_distance   = 0
	
	if entity.environment.max_height_above_ground ~= nil then
		max_ground_distance = entity.environment.max_height_above_ground
	end 
	
	if entity.environment.min_height_above_ground ~= nil then
		min_ground_distance = entity.environment.min_height_above_ground
	end

	if entity.data.movement.canfly == nil or
		entity.data.movement.canfly == false then
		max_ground_distance = 1	
	end

	return min_ground_distance,max_ground_distance
end

-------------------------------------------------------------------------------
-- name: pos_is_ok(pos,entity)
--
--! @brief check if a position is suitable for an mob
--! @ingroup environment
--
--! @param pos position to check
--! @param entity mob to check
--! @param dont_do_jumpcheck
--! @return suitability of position for mob values:
--!           -ok                    -@>position is ok                         
--!           -collision             -@>position is within a node
--!           -collision_jumpable    -@>position is within a node that can be jumped onto
--!           -drop                  -@>position is a drop
--!           -drop_above_water      -@>position is to far above water
--!           -above_water           -@>position is right over water
--!           -in_water              -@>position is within a water node(source or flow)
--!			  -in_air                -@>position is in air
--!           -above_limit           -@>position is above level limit
--!           -below_limit           -@>position is below level limit
--!           -wrong_surface         -@>position is above surface mob shouldn't be
--!           -invalid               -@>unable to check position
-------------------------------------------------------------------------------
function environment.pos_is_ok(pos,entity,dont_do_jumpcheck)

	local min_ground_distance,max_ground_distance = environment.get_min_max_ground_dist(entity)
	
	local cornerpositions = {}
	
	table.insert(cornerpositions,pos)
	--read positions at corners
	table.insert(cornerpositions,{x=pos.x + entity.collisionbox[4] -0.01,y=pos.y,z=pos.z + entity.collisionbox[6] -0.01})
	table.insert(cornerpositions,{x=pos.x + entity.collisionbox[4] -0.01,y=pos.y,z=pos.z + entity.collisionbox[3] +0.01})
	table.insert(cornerpositions,{x=pos.x + entity.collisionbox[1] +0.01,y=pos.y,z=pos.z + entity.collisionbox[6] -0.01})
	table.insert(cornerpositions,{x=pos.x + entity.collisionbox[1] +0.01,y=pos.y,z=pos.z + entity.collisionbox[3] +0.01})
	
	local lastpos = nil
	
	local retval = "temp_ok"
	
	--check if mob at pos will be in correct environment
	for i=1,#cornerpositions,1 do
		if not mobf_pos_is_same(lastpos,cornerpositions[i]) then
			local node_to_check = minetest.env:get_node(cornerpositions[i])
			
			if node_to_check == nil then
				mobf_bug_warning(LOGLEVEL_ERROR,"MOBF: BUG!!!! checking position with invalid node")
				retval = "invalid"
				break
			end
			
			if not environment.is_media_element(node_to_check.name,entity.environment.media) == true then
				dbg_mobf.environment_lvl3("MOBF: " .. i .. ": " .. 
					printpos(cornerpositions[i]) .. " -- " .. printpos(pos) .. 
					" not within environment")
				
				if mobf_pos_is_same(pos,cornerpositions[i]) then
					if node_to_check.name == "default:water_source" or 
						node_to_check.name == "default:water_flowing" then
						retval = "in_water"
						break
					end

					if node_to_check.name == "air" then
						retval = "in_air"
						break
					end
					
					--TODO maybe replace by "invalid medium"
				else
					retval = "collision"
				end
			end
		end
		lastpos = cornerpositions[i]
	end
	
	--
	if retval == "temp_ok" then
		dbg_mobf.environment_lvl2("MOBF: \tin environment")
		local ground_distance = mobf_ground_distance(pos,entity.environment.media)
		
		--following return codes are only usefull for non flying
		if entity.data.movement.canfly == nil or
			entity.data.movement.canfly == false then

			if mobf_above_water(pos) then
				
				if ground_distance > max_ground_distance then
					dbg_mobf.environment_lvl2("MOBF: \tdropping above water")
					retval = "drop_above_water"
				end
				dbg_mobf.environment_lvl2("MOBF: \tabove water")
				retval = "above_water"
			end

			if ground_distance > max_ground_distance then
				dbg_mobf.environment_lvl2("MOBF: \tdropping "
					.. ground_distance .. " / " .. max_ground_distance)
				retval = "drop"
			else
				dbg_mobf.environment_lvl2("MOBF: \tsurface dependent")
				retval = environment.checksurface(pos,entity.environment.surfaces)
			end
		else
			local miny,maxy = environment.get_absolute_min_max_pos(entity.environment,pos)
			dbg_mobf.environment_lvl2("MOBF: \tflying mob detected, min: " 
				.. miny .. " max: " .. maxy .. " current: " .. pos.y)
			if pos.y < miny then
				retval = "below_limit"
			else if pos.y > maxy then
				retval = "above_limit"
			else
				retval = environment.checksurface(pos,entity.environment.surfaces)
			end end
		end
	end
	
	if retval == "collision" and not dont_do_jumpcheck then
		dbg_mobf.environment_lvl2("MOBF: check if pos is jumpable")
		local upper_pos_state = environment.pos_is_ok({x=pos.x,
																y=pos.y+1,
																z=pos.z},
																entity,true)
		if  upper_pos_state == "ok" then
			retval = "collision_jumpable"
		else
			dbg_mobf.environment_lvl2("MOBF: upper pos state was: " .. upper_pos_state)
		end
	end
	
	return retval
end

-------------------------------------------------------------------------------
-- name: get_default_gravity(pos,environment,canfly)
--
--! @brief get default acceleration depending on mobs medium and pos
--! @ingroup environment
--
--! @param pos position where to check gravity
--! @param media mobs movement medium
--! @param canfly is mob capable of flying?
--! @return y-acceleration
------------------------------------------------------------------------------
function environment.get_default_gravity(pos,media,canfly)

	if pos == nil then
		return nil
	end

	local node = minetest.env:get_node(pos)

	--if an mob can't fly or isn't within it's medium default acceleration 
	-- for it's current medium is applied
	if  canfly == nil or
		canfly == false or
		environment.is_media_element(node.name,media) == false
		then
		if (node.name == "air") then			
			return -9.81
		end
		
		if node.name == "default:water_source" or
			node.name == "default:water_flowing" then
			return -2.5
		end
		
		if node.name == "default:lava" then
			return 0.1
		end
		
		--mob is at invalid position thus returning default air acceleration
		return -9.81
	end
		
	return 0
end


-------------------------------------------------------------------------------
-- name: fix_base_pos(entity, middle_to_bottom)
--
--! @brief fix the mobs y position according to model or sprite height
--! @ingroup environment
--
--! @param entity mob to fix base position
--! @param center_to_bottom distance from center of mob to its bottom (absolute value)
--! @return new position set by function
------------------------------------------------------------------------------
function environment.fix_base_pos(entity, center_to_bottom)

	if center_to_bottom > 0.5 then
		
		local pos = entity.object:getpos()
	
		local node_pos = minetest.env:get_node(pos)
		
		local pos_to_check = {x=pos.x,y=pos.y-center_to_bottom+0.1,z=pos.z}
		local node_pos_check = minetest.env:get_node(pos_to_check)
		
		if node_pos ~= nil and
			node_pos_check ~= nil then
			dbg_mobf.environment_lvl3("MOBF: fixing y position / base position required? " 
				.. node_pos.name .. " " .. node_pos_check.name)
			if node_pos.name ~= node_pos_check.name then
				distance_to_ground = mobf_surface_distance(pos)
				
				pos.y = pos.y + (center_to_bottom - distance_to_ground +0.5)
				dbg_mobf.environment_lvl2("MOBF: fixing y position of " .. entity.data.name 
					.. " got distance " .. center_to_bottom .. " moving to " ..printpos(pos))
				entity.object:moveto(pos)
			end
		end
	end
	
	return entity.getbasepos(entity)
end

-------------------------------------------------------------------------------
-- name: register(name, environment)
--
--! @brief register an environment to mob framework
--! @ingroup environment
--
--! @param name id of environment
--! @param environment description of environment
--! @return true/false succesfully registred environment
-------------------------------------------------------------------------------
function environment.register(name, environment)

	if environment_list[name] ~= nil then
		return false
	end
	
	environment_list[name] = environment	
	return true	 
end

-------------------------------------------------------------------------------
-- name: pos_state_is_impossible(entity,pos)
--
--! @brief checks if a entity can be there (not if it would move there by its own)
--! @ingroup environment
--
--! @param entity entity to check
--! @param pos position to check
--! @return true entity may be there, entity can never be there
-------------------------------------------------------------------------------
function environment.possible_pos(entity,pos)
	local state = environment.pos_is_ok(pos,entity)

	if 	state == "collision" or
		state == "collision_jumpable" or
		state == "invalid" then
		return false
	end
	
	return true
end

--!@}

dofile (mobf_modpath .. "/environments/general_env_sets.lua")
dofile (mobf_modpath .. "/environments/flight_1.lua")
dofile (mobf_modpath .. "/environments/meadow.lua")
dofile (mobf_modpath .. "/environments/on_ground_1.lua")
dofile (mobf_modpath .. "/environments/on_ground_2.lua")
dofile (mobf_modpath .. "/environments/open_waters.lua")
dofile (mobf_modpath .. "/environments/shallow_waters.lua")
dofile (mobf_modpath .. "/environments/simple_air.lua")