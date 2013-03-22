-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file spawning.lua
--! @brief component containing spawning features
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--

--! @defgroup spawning Spawn mechanisms
--! @brief all functions and variables required for automatic mob spawning 
--! @ingroup framework_int
--! @{
--
--! @defgroup spawn_algorithms Spawn algorithms 
--! @brief spawn algorithms provided by mob framework (can be extended by mods)
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------
--! @class spawning
--! @brief spawning features
spawning = {}

--!@}

--! @brief registry for spawn algorithms
--! @memberof spawning
--! @private
mobf_spawn_algorithms = {}


-------------------------------------------------------------------------------
-- name: remove_uninitialized(entity,staticdata)
-- @function [parent=#spawning] remove_uninitialized
--
--! @brief remove a spawn point based uppon staticdata supplied
--! @memberof spawning
--
--! @param entity to remove
--! @param staticdata of mob
-------------------------------------------------------------------------------
function spawning.remove_uninitialized(entity, staticdata)
	--entity may be known in spawnlist
	if staticdata ~= nil then
		local permanent_data = mobf_deserialize_permanent_entity_data(staticdata)
		if (permanent_data.spawnpoint ~= nil) then
		
			--prepare information required to remove entity
			entity.dynamic_data = {}
			entity.dynamic_data.spawning = {}
			entity.dynamic_data.spawning.spawnpoint = permanent_data.spawnpoint

			spawning.remove(entity,"remove uninitialized")
		end
	else
		dbg_mobf.spawning_lvl1("MOBF: remove uninitialized entity=" .. tostring(entity))
		--directly remove it can't be known to spawnlist
		entity.object:remove()
	end	
end

-------------------------------------------------------------------------------
-- name: remove(entity)
-- @function [parent=#spawning] remove
--
--! @brief remove a mob
--! @memberof spawning
--
--! @param entity mob to remove
--! @param reason text to log as reason for removal
-------------------------------------------------------------------------------
function spawning.remove(entity,reason)
	local pos = entity.object:getpos()
	dbg_mobf.spawning_lvl3("MOBF: --> remove " .. printpos(pos))
	if entity ~= nil then
		entity.removed = true
		dbg_mobf.spawning_lvl1("MOBF: remove entity=" .. tostring(entity))
		if minetest.setting_getbool("mobf_log_removed_entities") then
			if reason == nil then
				reason = "unknown"
			end
			minetest.log(LOGLEVEL_NOTICE,"MOBF: removing " .. entity.data.name ..
				" at " .. printpos(pos) .. " due to: " .. reason)
		end
		entity.object:remove()
	else
		minetest.log(LOGLEVEL_ERROR,"Trying to delete an an non existant mob")
	end
	
	dbg_mobf.spawning_lvl3("MOBF: <-- remove")
end

-------------------------------------------------------------------------------
-- name: init_dynamic_data(entity)
-- @function [parent=#spawning] init_dynamic_data
--
--! @brief initialize dynamic data required for spawning
--! @memberof spawning
--
--! @param entity mob to initialize dynamic data
--! @param now current time
-------------------------------------------------------------------------------
function spawning.init_dynamic_data(entity,now)

	local data = {
		player_spawned = false,
		ts_dense_check = now,
		spawnpoint = entity.object:getpos(),
		original_spawntime = now,
	}
	
	entity.removed = false
	entity.dynamic_data.spawning = data
end



-------------------------------------------------------------------------------
-- name: check_population_density(mob)
-- @function [parent=#spawning] check_population_density
--
--! @brief check and fix if there are too many mobs within a specific range
--! @memberof spawning
--
--! @param entity mob to check
--! @param now current time
-------------------------------------------------------------------------------
function spawning.check_population_density(entity,now)
	
	if entity == nil or
		entity.dynamic_data == nil or
		entity.dynamic_data.spawning == nil then
		mobf_bug_warning(LOGLEVEL_ERROR,"MOBF BUG!!! " .. entity.data.name .. 
			" pop dense check called for entity with missing spawn data entity=" .. 
			tostring(entity))
		return
	end


	-- don't check if mob is player spawned
	if entity.dynamic_data.spawning.player_spawned == true then
		dbg_mobf.spawning_lvl1("MOBF: mob is player spawned skipping pop dense check")
		return
	end


	--don't do population check while fighting
	if entity.dynamic_data.combat ~= nil and
		entity.dynamic_data.combat.target ~= "" then
		return
	end


	--only check every 15 seconds
	if entity.dynamic_data.spawning.ts_dense_check + 15 > now then
		return	
	end

	entity.dynamic_data.spawning.ts_dense_check = now

	local entitypos = mobf_round_pos(entity.object:getpos())

	--mob either not initialized completely or a bug
	if mobf_pos_is_zero(entitypos) then
		return
	end
	
	local secondary_name = ""
	if entity.data.harvest ~= nil then
		secondary_name = entity.data.harvest.transform_to
	end

	local mob_count = mobf_mob_around(entity.data.modname..":"..entity.data.name,
										secondary_name,
										entitypos,
										entity.data.spawning.density,
										true)
	if  mob_count > 5 then
		entity.removed = true
		minetest.log(LOGLEVEL_WARNING,"MOBF: Too many ".. mob_count .. " ".. 
			entity.data.name.." at one place dying: " ..
			tostring(entity.dynamic_data.spawning.player_spawned))
		spawning.remove(entity, "population density check")
	else
		dbg_mobf.spawning_lvl3("Density ok only "..mob_count.." mobs around")
	end
end


-------------------------------------------------------------------------------
-- name: replace_entity(pos,name,spawnpos,health)
-- @function [parent=#spawning] replace_entity
--
--! @brief replace mob at a specific position by a new one
--! @memberof spawning
--
--! @param entity mob to replace
--! @param name of the mob to add
--! @param preserve preserve original spawntime
--! @return entity added or nil on error
-------------------------------------------------------------------------------
function spawning.replace_entity(entity,name,preserve)
	dbg_mobf.spawning_lvl3("MOBF: --> replace_entity("
		.. entity.data.name .. "|" .. name .. ")")
	
	if minetest.registered_entities[name] == nil then
		minetest.log(LOGLEVEL_ERROR,"MOBF: replace_entity: Bug no "
			..name.." is registred")
		return nil
	end
	
	-- avoid switching to same entity
	if entity.name == name then
		minetest.log(LOGLEVEL_INFO,"MOBF: not replacing " .. name .. 
			" by entity of same type!")
		return nil
	end
	

	-- get data to be transfered to new entity
	local pos             = mobf.get_basepos(entity)
	local health          = entity.object:get_hp()
	local temporary_dynamic_data = entity.dynamic_data
	local entity_orientation = entity.object:getyaw()
	
	if preserve == nil or preserve == false then
		temporary_dynamic_data.spawning.original_spawntime = mobf_get_current_time()
	end
	
	--calculate new y pos
	if minetest.registered_entities[name].collisionbox ~= nil then
		pos.y = pos.y - minetest.registered_entities[name].collisionbox[2]
	end
	

	--delete current mob
	dbg_mobf.spawning_lvl2("MOBF: replace_entity: removing " ..  entity.data.name)
	
	--unlink dynamic data (this should work but doesn't due to other bugs)
	entity.dynamic_data = nil
	
	--removing is done after exiting lua!
	spawning.remove(entity,"replaced")

	local newobject = minetest.env:add_entity(pos,name)
	local newentity = mobf_find_entity(newobject)

	if newentity ~= nil then
		if newentity.dynamic_data ~= nil then
			dbg_mobf.spawning_lvl2("MOBF: replace_entity: " ..  name .. 
							" added at " .. 
							printpos(newentity.dynamic_data.spawning.spawnpoint))
			newentity.dynamic_data = temporary_dynamic_data
			newentity.object:set_hp(health)
			newentity.object:setyaw(entity_orientation)
		else
			minetest.log(LOGLEVEL_ERROR,
				"MOBF: replace_entity: dynamic data not set for "..name..
				" maybe delayed activation?")
			newentity.dyndata_delayed = {
				data = temporary_dynamic_data,
				health = health,
				orientation = entity_orientation
			}
		end
	else
		minetest.log(LOGLEVEL_ERROR,
			"MOBF: replace_entity 4 : Bug no "..name.." has been created")
	end
	dbg_mobf.spawning_lvl3("MOBF: <-- replace_entity")
	return newentity
end

------------------------------------------------------------------------------
-- name: lifecycle()
-- @function [parent=#spawning] lifecycle
--
--! @brief check mob lifecycle
--! @memberof spawning
--
--! @return true/false still alive dead
-------------------------------------------------------------------------------
function spawning.lifecycle(entity,now)

	if entity.dynamic_data.spawning.original_spawntime ~= nil and
		entity.data.spawning.lifetime ~= nil then
	
		local lifetime = entity.data.spawning.lifetime
		
		local current_age = now - entity.dynamic_data.spawning.original_spawntime
	
		if current_age > 0 and 
			current_age > lifetime then
			dbg_mobf.spawning_lvl1("MOBF: removing animal due to limited lifetime")
			spawning.remove(entity," limited mob lifetime")
			return false
		end
	else
		entity.dynamic_data.spawning.original_spawntime = now
	end

	return true
end

------------------------------------------------------------------------------
-- name: register_spawn_algorithm()
-- @function [parent=#spawning] register_spawn_algorithm
--
--! @brief print current spawn statistics
--! @memberof spawning
--
--! @return true/false successfully added spawn algorithm
-------------------------------------------------------------------------------
function spawning.register_spawn_algorithm(name, spawnfunc, cleanupfunc)

	if (mobf_spawn_algorithms[name] ~= nil) then
		return false
	end
	
	local new_algorithm = {}
	
	new_algorithm.register_spawn	= spawnfunc
	new_algorithm.register_cleanup 	= cleanupfunc 
		
	mobf_spawn_algorithms[name] = new_algorithm

	return true
end

------------------------------------------------------------------------------
-- name: spawn_and_check(name,suffix,pos)
-- @function [parent=#spawning] spawn_and_check
--
--! @brief spawn an entity and check for presence
--! @memberof spawning
--
--! @return spawned mob entity
-------------------------------------------------------------------------------
function spawning.spawn_and_check(name,suffix,pos,text)
	local newobject = minetest.env:add_entity(pos,name .. suffix)
	
	if newobject then
		local newentity = mobf_find_entity(newobject)
		
		if newentity == nil then
			dbg_mobf.spawning_lvl3("MOBF BUG!!! no " .. name..
				" entity has been created by " .. text .. "!")
			mobf_bug_warning(LOGLEVEL_ERROR,"BUG!!! no " .. name..
				" entity has been created by " .. text .. "!")
		else
			dbg_mobf.spawning_lvl2("MOBF: spawning "..name.." entity by " .. 
				text .. " at position ".. printpos(pos))
			minetest.log(LOGLEVEL_INFO,"MOBF: spawning "..name.." entity by " .. 
				text .. " at position ".. printpos(pos))
			return newentity
		end
	else
		dbg_mobf.spawning_lvl3("MOBF BUG!!! no "..name..
			" object has been created by " .. text .. "!")
		mobf_bug_warning(LOGLEVEL_ERROR,"MOBF BUG!!! no "..name..
			" object has been created by " .. text .. "!")
	end
	
	return nil
end


------------------------------------------------------------------------------
-- name: get_center(min,max,current_step,interval)
-- @function [parent=#spawning] get_center
--
--! @brief calculate center and deltas
--! @memberof spawning
--
--! @return center,delta
-------------------------------------------------------------------------------
function spawning.get_center(min,max,current_step,interval)

	dbg_mobf.spawning_lvl3("MOBF: get_center params: " .. min .. " " .. max .. 
		" " .. current_step .. " " .. interval )
	local abs_min = min + interval * (current_step-1)
	local abs_max = abs_min + interval
	
	if abs_max > max then
		abs_max = max
	end
	
	local delta = (abs_max - abs_min) / 2 
	
	return (abs_min + delta),delta
end

------------------------------------------------------------------------------
-- name: divide_mapgen_entity(minp,maxp,density,name,spawnfunc)
-- @function [parent=#spawning] divide_mapgen_entity
--
--! @brief divide mapblock into 2d chunks and call spawnfunc with randomized parameters for each
--! @memberof spawning
--! @param minp minimum 3d point of map block
--! @param maxp maximum 3d point of map block
--! @param spawndata spawndata
--! @param name name of entity to spawn
--! @param spawnfunc function to use for spawning
--! @param maxtries maximum number of tries to place a spawner
--
-------------------------------------------------------------------------------
function spawning.divide_mapgen_entity(minp,maxp,spawndata,name,spawnfunc,maxtries)

	local density = spawndata.density
	
	dbg_mobf.spawning_lvl3("MOBF: divide_mapgen params: ")
	dbg_mobf.spawning_lvl3("MOBF:	" .. dump(spawndata.density))
	dbg_mobf.spawning_lvl3("MOBF:	" .. dump(name))
	dbg_mobf.spawning_lvl3("MOBF:	" .. dump(spawnfunc))
	
	if maxtries == nil then
		maxtries = 5
	end

	local starttime = mobf_get_time_ms()
	
	local min_x = MIN(minp.x,maxp.x)
	local min_y = MIN(minp.y,maxp.x)
	local min_z = MIN(minp.z,maxp.z)
	
	local max_x = MAX(minp.x,maxp.x)
	local max_y = MAX(minp.y,maxp.y)
	local max_z = MAX(minp.z,maxp.z)
	
	
	local xdivs = math.floor(((max_x - min_x) / spawndata.density) +1)
	local zdivs = math.floor(((max_z - min_z) / spawndata.density) +1)
	
	dbg_mobf.spawning_lvl3("MOBF: X: " .. min_x .. "-->" .. max_x) 
	dbg_mobf.spawning_lvl3("MOBF: Z: " .. min_z .. "-->" .. max_z)
	dbg_mobf.spawning_lvl3("MOBF: Y: " .. min_y .. "-->" .. max_y)
	dbg_mobf.spawning_lvl3("MOBF: generating in " .. xdivs .. " | " .. zdivs .. " chunks")
	
	for i = 1, xdivs,1 do
	for j = 1, zdivs,1 do
	
		local x_center,x_delta = spawning.get_center(min_x,max_x,i,spawndata.density)
		local z_center,z_delta = spawning.get_center(min_z,max_z,j,spawndata.density)
		
		local surface_center = mobf_get_surface(x_center,z_center,min_y,max_y)
		
		local centerpos = {x=x_center,y=surface_center,z=z_center}
		
		dbg_mobf.spawning_lvl3("MOBF: center is (" .. x_center .. "," .. z_center .. ")"
			.."  --> (".. x_delta .."," .. z_delta .. ")")
		
		--check if there is already a mob of same type within area
		if surface_center  then
			local mobs_around = mobf_spawner_around(name,centerpos,spawndata.density)
			if mobs_around == 0 then
				dbg_mobf.spawning_lvl3("no " .. name .. " within range of " .. 
					spawndata.density .. " around " ..printpos(centerpos))
				for i= 0, maxtries do
					local x_try = math.random(-x_delta,x_delta)
					local z_try = math.random(-z_delta,z_delta)
					
					local pos = { x= x_center + x_try,
									z= z_center + z_try }
					
					--do place spawners in center of block
					pos.x = math.floor(pos.x + 0.5)
					pos.z = math.floor(pos.z + 0.5)
					
					if spawnfunc(name,pos,min_y,max_y,spawndata) then
						break
					end
				end	--for -> 5
			end --mob around
		else
			dbg_mobf.spawning_lvl3("MOBF: didn't find surface for " ..printpos(centerpos))
		end --surface_center
	end -- for z divs
	end -- for x divs
	dbg_mobf.spawning_lvl3("magen ended")
end

------------------------------------------------------------------------------
-- name: divide_mapgen(minp,maxp,density,name,spawnfunc)
-- @function [parent=#spawning] divide_mapgen
--
--! @brief divide mapblock into 2d chunks and call spawnfunc with randomized parameters for each
--! @memberof spawning
--! @param minp minimum 3d point of map block
--! @param maxp maximum 3d point of map block
--! @param density chunk size
--! @param name name of entity to spawn
--! @param secondary_name secondary name of entity
--! @param spawnfunc function to use for spawning
--! @param surfacefunc use this function to detect surface
--! @param maxtries maximum number of tries to place a entity
--
-------------------------------------------------------------------------------
function spawning.divide_mapgen(minp,maxp,density,name,secondary_name,spawnfunc,surfacefunc,maxtries)
	local starttime = mobf_get_time_ms()
	dbg_mobf.spawning_lvl3("MOBF: divide_mapgen params: ")
	dbg_mobf.spawning_lvl3("MOBF:	" .. dump(density))
	dbg_mobf.spawning_lvl3("MOBF:	" .. dump(name))
	dbg_mobf.spawning_lvl3("MOBF:	" .. dump(spawnfunc))
	
	if maxtries == nil then
		maxtries = 5
	end

	local starttime = mobf_get_time_ms()
	
	local min_x = MIN(minp.x,maxp.x)
	local min_y = MIN(minp.y,maxp.x)
	local min_z = MIN(minp.z,maxp.z)
	
	local max_x = MAX(minp.x,maxp.x)
	local max_y = MAX(minp.y,maxp.y)
	local max_z = MAX(minp.z,maxp.z)
	
	
	local xdivs = math.floor(((max_x - min_x) / density) +1)
	local zdivs = math.floor(((max_z - min_z) / density) +1)
	
	dbg_mobf.spawning_lvl3("MOBF: X: " .. min_x .. "-->" .. max_x) 
	dbg_mobf.spawning_lvl3("MOBF: Z: " .. min_z .. "-->" .. max_z)
	dbg_mobf.spawning_lvl3("MOBF: Y: " .. min_y .. "-->" .. max_y)
	dbg_mobf.spawning_lvl3("MOBF: generating in " .. xdivs .. " | " .. zdivs .. " chunks")
	
	for i = 1, xdivs,1 do
	for j = 1, zdivs,1 do
	
	local x_center,x_delta = spawning.get_center(min_x,max_x,i,density)
	local z_center,z_delta = spawning.get_center(min_z,max_z,j,density)
	
	local surface_center = surfacefunc(x_center,z_center,min_y,max_y)
	
	local centerpos = {x=x_center,y=surface_center,z=z_center}
	
	dbg_mobf.spawning_lvl3("MOBF: center is (" .. x_center .. "," .. z_center .. ") --> (".. x_delta .."," .. z_delta .. ")")
	
	--check if there is already a mob of same type within area
	if surface_center  then
		local mobs_around = mobf_mob_around(name,secondary_name,centerpos,density,true)
		if mobs_around == 0 then
			dbg_mobf.spawning_lvl3("no " .. name .. " within range of " .. density .. " around " ..printpos(centerpos))
				i= 0, maxtries, 1 do
				local x_try = math.random(-x_delta,x_delta)
				local z_try = math.random(-z_delta,z_delta)
				
				local pos = { x= x_center + x_try,
								z= z_center + z_try }
				
				pos.y = surfacefunc(pos.x,pos.z,min_y,max_y)
				
				if pos.y and spawnfunc(name,pos,min_y,max_y) then
					break
				end
			end --for -> 5
		end --mob around
	else
		dbg_mobf.spawning_lvl3("MOBF: didn't find surface for " ..printpos(centerpos))
	end --surface_center
	end -- for z divs
	end -- for x divs
	mobf_warn_long_fct(starttime,"on_mapgen" .. name,"mapgen")
	dbg_mobf.spawning_lvl3("magen ended")
end

------------------------------------------------------------------------------
-- name: register_spawner_entity(mobname,secondary_mobname,spawndata,environment,spawnfunc)
-- @function [parent=#spawning] register_spawner_entity
--
--! @brief register a spawner entity
--! @memberof spawning
--
--! @param mobname name of mob
--! @param secondary_mobname secondary name of mob
--! @param spawndata spawning information to use
--! @param environment what environment is good for mob
--! @param spawnfunc function to call for spawning
--
--! @return
-------------------------------------------------------------------------------
function spawning.register_spawner_entity(mobname,secondary_mobname,spawndata,environment,spawnfunc)
	minetest.register_entity(mobname .. "_spawner",
		 {
			physical        = false,
			collisionbox    = { 0.0,0.0,0.0,0.0,0.0,0.0},
			visual          = "sprite",
			textures        = { "invisible.png^[makealpha:128,0,0^[makealpha:128,128,0" },
			
			
			on_step = function(self,dtime)
				self.spawner_time_passed = self.spawner_time_passed -dtime

				
				if self.spawner_time_passed < 0 then
					local starttime = mobf_get_time_ms()
					spawnfunc(self)
					mobf_warn_long_fct(starttime,"spawnfunc " .. self.spawner_mob_name,"spawnfunc")
				end
			end,
			
			on_activate = function(self,staticdata)
				if self.spawner_mob_transform == nil then
					self.spawner_mob_transform = ""
				end
			end,
			
			spawner_mob_name 		= mobname,
			spawner_mob_transform 	= secondary_mobname,
			spawner_time_passed 	= 1,
			spawner_mob_env         = environment,
			spawner_mob_spawndata   = spawndata,
		})

end

------------------------------------------------------------------------------
-- name: register_cleanup_spawner(mobname)
-- @function [parent=#spawning] register_cleanup_spawner
--
--! @brief register an entity to cleanup spawners
--! @memberof spawning
-------------------------------------------------------------------------------
function spawning.register_cleanup_spawner(mobname)
	minetest.register_entity(mobname .. "_spawner",
		{
			on_activate = function(self,staticdata)
				self.object:remove()
			end
		})
end

--include spawn algorithms
dofile (mobf_modpath .. "/spawn_algorithms/at_night.lua")
dofile (mobf_modpath .. "/spawn_algorithms/forrest.lua")
dofile (mobf_modpath .. "/spawn_algorithms/in_shallow_water.lua")
dofile (mobf_modpath .. "/spawn_algorithms/shadows.lua")
dofile (mobf_modpath .. "/spawn_algorithms/willow.lua")
dofile (mobf_modpath .. "/spawn_algorithms/big_willow.lua")
dofile (mobf_modpath .. "/spawn_algorithms/in_air1.lua")
dofile (mobf_modpath .. "/spawn_algorithms/none.lua")
dofile (mobf_modpath .. "/spawn_algorithms/deep_large_caves.lua")