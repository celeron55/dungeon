-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file willow.lua
--! @brief spawn algorithm willow
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--
--! @addtogroup spawn_algorithms
--! @{
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- name: mobf_spawn_on_willow(mob_name,mob_transform,spawning_data,environment)
--
--! @brief find a place on willow to spawn a mob
--
--! @param mob_name name of mob
--! @param mob_transform secondary name of mob
--! @param spawning_data spawning configuration
--! @param environment environment of mob
-------------------------------------------------------------------------------
function mobf_spawn_on_willow(mob_name,mob_transform,spawning_data,environment) 
	minetest.log(LOGLEVEL_WARNING,"MOBF: using deprecated abm based spawn algorithm \"spawn_on_willow\" most likely causing lag in server!\t Use spawn_on_willow_mapgen instead!")
	minetest.log(LOGLEVEL_INFO,"MOBF:\tregistering willow spawn abm callback for mob "..mob_name)
	
	local media = nil
	
	if environment ~= nil and
		environment.media ~= nil then
		media = environment.media	
	end

	minetest.register_abm({
			nodenames = { "default:dirt_with_grass" },
			neighbors = media,
			interval = 7200,
			chance = math.floor(1/spawning_data.rate),
			action = function(pos, node, active_object_count, active_object_count_wider)
				local starttime = mobf_get_time_ms()
				local pos_above = {
					x = pos.x,
					y = pos.y + 1,
					z = pos.z
				}

				--never try to spawn an mob at pos (0,0,0) it's initial entity spawnpos and
				--used to find bugs in initial spawnpoint setting code
				if mobf_pos_is_zero(pos) then
					mobf_warn_long_fct(starttime,"mobf_spawn_on_willow")
					return
				end

				--check if there s enough space above to place mob
				if mobf_air_above(pos,spawning_data.height) ~= true then
					mobf_warn_long_fct(starttime,"mobf_spawn_on_willow")
					return
				end

				local node_above = minetest.env:get_node(pos_above)

				if mob_name == nil then
					mobf_bug_warning(LOGLEVEL_ERROR,"MOBF: BUG!!! mob name not available")
				else
					--print("Try to spawn mob: "..mob_name)
					if node_above.name == "air" then
						--print("Find mobs of same type around:"..mob_name.. " pop dens: ".. population_density)
					   if mobf_mob_around(mob_name,mob_transform,pos,spawning_data.density,true) == 0 then
							local newobject = minetest.env:add_entity(pos_above,mob_name .. "__default")

							local newentity = mobf_find_entity(newobject)
							
							if newentity == nil then
								mobf_bug_warning(LOGLEVEL_ERROR,"MOBF: BUG!!! no "..mob_name.." has been created!")
							end
							minetest.log(LOGLEVEL_INFO,"MOBF: Spawning "..mob_name.." on willow at position "..printpos(pos))
						end
					end
				end
				mobf_warn_long_fct(starttime,"mobf_spawn_on_willow")
			end,
		})
end

-------------------------------------------------------------------------------
-- name: mobf_spawn_on_willow_mapgen(mob_name,mob_transform,spawning_data,environment)
--
--! @brief find a place on willow to spawn a mob on map generation
--
--! @param mob_name name of mob
--! @param mob_transform secondary name of mob
--! @param spawning_data spawning configuration
--! @param environment environment of mob
-------------------------------------------------------------------------------
function mobf_spawn_on_willow_mapgen(mob_name,mob_transform,spawning_data,environment)
	minetest.log(LOGLEVEL_INFO,"MOBF:\tregistering willow mapgen spawn mapgen callback for mob "..mob_name)
	
	--add mob on map generation
	minetest.register_on_generated(function(minp, maxp, seed)
		spawning.divide_mapgen(minp,maxp,spawning_data.density,mob_name,mob_transform,
		
		function(name,pos,min_y,max_y)
			
			--check if there s enough space above to place mob
			if mobf_air_above(pos,spawning_data.height) then
				dbg_mobf.spawning_lvl3("enough air above " ..printpos(centerpos) .. " minimum is: " .. spawning_data.height )
				local spawnpos = {x=pos.x,y=pos.y+1,z=pos.z}
				spawning.spawn_and_check(name,"__default",spawnpos,"on_willow_mapgen")
				return true
			end -- air_above
			return false
		end,
		mobf_get_sunlight_surface,
		5)
	end)
 end --end spawn algo
--!@}

spawning.register_spawn_algorithm("willow", mobf_spawn_on_willow)
spawning.register_spawn_algorithm("willow_mapgen", mobf_spawn_on_willow_mapgen)