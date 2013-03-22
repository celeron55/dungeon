-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file in_shallow_water.lua
--! @brief spawn algorithm for shallow water spawning
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--
--! @addtogroup spawn_algorithms
--! @{
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- name: mobf_spawn_in_shallow_water(mob_name,mob_transform,spawning_data,environment)
--
--! @brief find a place in water to spawn mob
--
--! @param mob_name name of mob
--! @param mob_transform secondary name of mob
--! @param spawning_data spawning configuration
--! @param environment environment of mob
-------------------------------------------------------------------------------

function mobf_spawn_in_shallow_water(mob_name,mob_transform,spawning_data,environment) 

	minetest.log(LOGLEVEL_INFO,"MOBF: \tregistering shallow water spawn abm callback for mob "..mob_name)
	
	local media = nil
	
	if environment ~= nil and
		environment.media ~= nil then
		media = environment.media	
	end

	minetest.register_abm({
			nodenames = { "default:water_source" },
			neighbors = media,
			interval = 60,
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
					mobf_warn_long_fct(starttime,"mobf_spawn_in_shallow_water")
					return
				end

				--check if water is to deep
				if mobf_air_distance(pos) < 10 then
					mobf_warn_long_fct(starttime,"mobf_spawn_in_shallow_water")
					return
				end

				if mob_name == nil then
					minetest.log(LOGLEVEL_ERROR,"MOBF: Bug!!! mob name not available")
				else
					--print("Try to spawn mob: "..mob_name)
				
                    if mobf_mob_around(mob_name,mob_transform,pos,spawning_data.density,true) == 0 then

						if minetest.env:find_node_near(pos, 10, {"default:dirt",
                                                                "default:dirt_with_grass"}) ~= nil then

							local newobject = minetest.env:add_entity(pos,mob_name .. "__default")

							local newentity = mobf_find_entity(newobject)

							if newentity == nil then
								minetest.log(LOGLEVEL_ERROR,"MOBF: Bug!!! no "..mob_name.." has been created!")
							end

							minetest.log(LOGLEVEL_INFO,"MOBF: Spawning "..mob_name.." in shallow water "..printpos(pos))
						--else
							--print(printpos(pos).." not next to ground")
						end			
					end
				end
				mobf_warn_long_fct(starttime,"mobf_spawn_in_shallow_water")
			end,
		})
end

-------------------------------------------------------------------------------
-- name: mobf_spawn_in_shallow_water_entity(mob_name,mob_transform,spawning_data,environment)
--
--! @brief find a place in shallow water
--
--! @param mob_name name of mob
--! @param mob_transform secondary name of mob
--! @param spawning_data spawning configuration
--! @param environment environment of mob
-------------------------------------------------------------------------------
function mobf_spawn_in_shallow_water_entity(mob_name,mob_transform,spawning_data,environment)
	minetest.log(LOGLEVEL_INFO,"MOBF:\tregistering in shallow water mapgen spawn mapgen callback for mob "..mob_name)
	
	spawning.register_spawner_entity(mob_name,mob_transform,spawning_data,environment,
		function(self)
			
			local pos = self.object:getpos()
			local good = true
			
			dbg_mobf.spawning_lvl3("MOBF: " .. dump(self.spawner_mob_env))
			
			--check if own position is good
			local node_to_check = minetest.env:get_node(pos)
			
			if node_to_check ~= nil and
				node_to_check.name ~= "default:water_flowing" and
				node_to_check.name ~= "default:water_source" then
				dbg_mobf.spawning_lvl2("MOBF: spawner " .. printpos(pos) .. " not in water but:" .. dump(node_to_check))
				good = false
			end
			
			local found_nodes = minetest.env:find_nodes_in_area({x=pos.x-1,y=pos.y-1,z=pos.z-1},
																{x=pos.x+1,y=pos.y+1,z=pos.z+1},
																{ "default:water_flowing","default:water_source"} )
			if #found_nodes < 4 then
				dbg_mobf.spawning_lvl2("MOBF: spawner " .. printpos(pos) .. " not enough water around: " ..  #found_nodes)
				good = false
			end
			
			--check if water is to deep
			if mobf_air_distance(pos) > 10 then
				dbg_mobf.spawning_lvl2("MOBF: spawner " .. printpos(pos) .. " air distance to far no dirt around")
				good = false
			end
			
			--make sure we're near green coast
			if minetest.env:find_node_near(pos, 10, 
				{"default:dirt","default:dirt_with_grass"}) == nil then
				dbg_mobf.spawning_lvl2("MOBF: spawner " .. printpos(pos) .. " no dirt around")
				good = false
			end
			
			if not good then
				dbg_mobf.spawning_lvl2("MOBF: not spawning, spawner for " .. self.spawner_mob_name .. " somehow got to bad place " .. printpos(pos))
				--TODO try to move spawner to better place
				
				self.spawner_time_passed = self.spawner_mob_spawndata.respawndelay
				return
			end
			

			if mobf_mob_around(self.spawner_mob_name,
							   self.spawner_mob_transform,
							   pos,
							   self.spawner_mob_spawndata.density,true) == 0 then

				spawning.spawn_and_check(self.spawner_mob_name,"__default",pos,"in_shallow_water_spawner_ent")
				self.spawner_time_passed = self.spawner_mob_spawndata.respawndelay
			else
				self.spawner_time_passed = self.spawner_mob_spawndata.respawndelay
				dbg_mobf.spawning_lvl2("MOBF: not spawning " .. self.spawner_mob_name .. " there's a mob around")
			end
		end)
		
	--add mob spawner on map generation
	minetest.register_on_generated(function(minp, maxp, seed)
	
		spawning.divide_mapgen_entity(minp,maxp,spawning_data,mob_name,
			function(name,pos,min_y,max_y)
				dbg_mobf.spawning_lvl3("MOBF: trying to create a spawner for " .. name .. " at " ..printpos(pos))
				local surface = mobf_get_surface(pos.x,pos.z,min_y,max_y)
				
				if surface then
					pos.y=surface - math.random(2,10)
					
					local node_to_check = minetest.env:get_node(pos)
					
					if node_to_check ~= nil and	
						node_to_check.name == "default:water_source" or
						node_to_check.name == "default:water_flowing" then
						spawning.spawn_and_check(name,"_spawner",pos,"in_shallow_water_spawner")
						return true
					else
						dbg_mobf.spawning_lvl3("MOBF:	pos to add spawner is not water but: " .. dump(node_to_check))
					end
				else
					dbg_mobf.spawning_lvl3("MOBF:	unable to find surface")
				end
				return false
			end,
			15
			)
    end) --register mapgen
 end --end spawn algo
--!@}

spawning.register_spawn_algorithm("in_shallow_water", mobf_spawn_in_shallow_water)
spawning.register_spawn_algorithm("in_shallow_water_spawner", mobf_spawn_in_shallow_water_entity,spawning.register_cleanup_spawner)