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
-- name: mobf_spawn_on_big_willow(mob_name,mob_transform,spawning_data,environment)
--
--! @brief find a place on big willow to spawn a mob
--
--! @param mob_name name of mob
--! @param mob_transform secondary name of mob
--! @param spawning_data spawning configuration
--! @param environment environment of mob
-------------------------------------------------------------------------------
function mobf_spawn_on_big_willow(mob_name,mob_transform,spawning_data,environment) 
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

				if mob_name == nil then
					mobf_bug_warning(LOGLEVEL_ERROR,"MOBF: BUG!!! mob name not available")
				else
					if mobf_mob_around(mob_name,mob_transform,pos,spawning_data.density,true) == 0 then					
						local pos_is_big_willow = true
				
						for x=pos.x-2,pos.x+2,1 do
						for z=pos.z-2,pos.z+2,1 do
							local node_to_check = minetest.env:getnode({x=x,y=pos.y,z=z})
				
							if node_to_check == nil or
								node_to_check.name ~= "default:dirt_with_grass" then
								break
							end
						
							--check if there s enough space above to place mob
							if not mobf_air_above({x=x,y=pos.y,z=z},spawning_data.height) then
								pos_is_big_willow = false
								break
							end
						end
						end
						
						if pos_is_big_willow then
							dbg_mobf.spawning_lvl3("willow is big enough " ..printpos(centerpos))
							local spawnpos = {x=pos.x,y=pos.y+1,z=pos.z}
							spawning.spawn_and_check(name,"__default",spawnpos,"on_big_willow_mapgen")
							return true
						end
					end
				end
				mobf_warn_long_fct(starttime,"mobf_spawn_on_willow")
			end,
		})
end

-------------------------------------------------------------------------------
-- name: mobf_spawn_on_big_willow_mapgen(mob_name,mob_transform,spawning_data,environment)
--
--! @brief find a place on big willow to spawn a mob on map generation
--
--! @param mob_name name of mob
--! @param mob_transform secondary name of mob
--! @param spawning_data spawning configuration
--! @param environment environment of mob
-------------------------------------------------------------------------------
function mobf_spawn_on_big_willow_mapgen(mob_name,mob_transform,spawning_data,environment)
	minetest.log(LOGLEVEL_INFO,"MOBF:\tregistering willow mapgen spawn mapgen callback for mob "..mob_name)
	
	--add mob on map generation
	minetest.register_on_generated(function(minp, maxp, seed)
		spawning.divide_mapgen(minp,maxp,spawning_data.density,mob_name,mob_transform,
		
		function(name,pos,min_y,max_y)
			local pos_is_big_willow = true

			for x=pos.x-2,pos.x+2,1 do
			for z=pos.z-2,pos.z+2,1 do
				local node_to_check = minetest.env:get_node({x=x,y=pos.y,z=z})
				if node_to_check == nil or
					node_to_check.name ~= "default:dirt_with_grass" then
					pos_is_big_willow = false
					break
				end
			
				--check if there s enough space above to place mob
				if not mobf_air_above({x=x,y=pos.y,z=z},spawning_data.height) then
					pos_is_big_willow = false
					break
				end
			end
			end
			
			if pos_is_big_willow then
				dbg_mobf.spawning_lvl3("willow is big enough " ..printpos(centerpos))
				local spawnpos = {x=pos.x,y=pos.y+1,z=pos.z}
				spawning.spawn_and_check(name,"__default",spawnpos,"on_big_willow_mapgen")
				return true
			end
			
			return false
		end,
		mobf_get_sunlight_surface,
		20)
	end)
 end --end spawn algo
--!@}

spawning.register_spawn_algorithm("big_willow", mobf_spawn_on_big_willow)
spawning.register_spawn_algorithm("big_willow_mapgen", mobf_spawn_on_big_willow_mapgen)