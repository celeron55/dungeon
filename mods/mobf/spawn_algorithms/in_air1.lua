-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file in_air1.lua
--! @brief spawn algorithm for birds
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--
--! @addtogroup spawn_algorithms
--! @{
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- name: mobf_spawn_in_air1(mob_name,mob_transform,spawning_data,environment)
--
--! @brief find a place in sky to spawn mob
--
--! @param mob_name name of mob
--! @param mob_transform secondary name of mob
--! @param spawning_data spawning configuration
--! @param environment environment of mob
-------------------------------------------------------------------------------

function mobf_spawn_in_air1(mob_name,mob_transform,spawning_data,environment) 

	minetest.log(LOGLEVEL_INFO,"MOBF:\tregistering in air 1 spawn abm callback for mob "..mob_name)
	
	local media = nil
	
	if environment ~= nil and
		environment.media ~= nil then
		media = environment.media	
	end

	minetest.register_abm({
			nodenames = { "default:dirt", "default:dirt_with_grass" },
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
				
				local node_above = minetest.env:get_node(pos_above)
				
				if node_above.name ~= "air" then
					mobf_warn_long_fct(starttime,"mobf_spawn_in_air1")
					return
				end

				
				local pos_spawn = {
					x = pos.x,
					y = pos.y + 10 + math.floor(math.random(0,10)),
					z = pos.z
				}
				
				local node_spawn = minetest.env:get_node(pos_spawn)



				if node_spawn.name ~= "air" then
					mobf_warn_long_fct(starttime,"mobf_spawn_in_air1")
					return
				end
				
				if mob_name == nil then
					minetest.log(LOGLEVEL_ERROR,"MOBF: Bug!!! mob name not available")
				else
					--print("Try to spawn mob: "..mob_name)				

                    if mobf_mob_around(mob_name,mob_transform,pos,spawning_data.density,true) == 0 then

						spawning.spawn_and_check(mob_name,"__default",pos_spawn,"in_air1")
					end
				end
				mobf_warn_long_fct(starttime,"mobf_spawn_in_air1")
			end,
		})
end

-------------------------------------------------------------------------------
-- name: mobf_spawn_in_air1_spawner(mob_name,mob_transform,spawning_data,environment)
--
--! @brief a spawner based spawn spawn algorithm
--
--! @param mob_name name of mob
--! @param mob_transform secondary name of mob
--! @param spawning_data spawning configuration
--! @param environment environment of mob
-------------------------------------------------------------------------------
function mobf_spawn_in_air1_spawner(mob_name,mob_transform,spawning_data,environment)
	
	spawning.register_spawner_entity(mob_name,mob_transform,spawning_data,environment,
		function(self)
			local pos = self.object:getpos()
			local good = true
			
			dbg_mobf.spawning_lvl3("MOBF: " .. dump(self.spawner_mob_env))
			
			--check if own position is good
			for x=pos.x-1,pos.x+1,1 do
			for y=pos.y-1,pos.y+1,1 do
			for z=pos.z-1,pos.z+1,1 do
			
				local node_to_check = minetest.env:get_node({x=x,y=y,z=z})
				
				if node_to_check == nil then
					good = false
				else
					dbg_mobf.spawning_lvl3("MOBF: checking " .. node_to_check.name)
					if not mobf_contains(self.spawner_mob_env.media,node_to_check.name) then
						good = false
					end
				end
			end
			end
			end
			
			if not good then
				dbg_mobf.spawning_lvl2("MOBF: not spawning, spawner for " .. self.spawner_mob_name .. " somehow got to bad place")
				--TODO try to move spawner to better place
				
				self.spawner_time_passed = self.spawner_mob_spawndata.respawndelay
				return
			end
			

			if mobf_mob_around(self.spawner_mob_name,
							   self.spawner_mob_transform,
							   pos,
							   self.spawner_mob_spawndata.density,true) == 0 then

				spawning.spawn_and_check(self.spawner_mob_name,"__default",pos,"in_air1_spawner_ent")
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
					pos.y=surface + 8 + math.random(0,5)
					
					if mobf_air_above(pos,10) then
						spawning.spawn_and_check(name,"_spawner",pos,"in_air1_spawner")
						return true
					end
				end
				return false
			end)
    end) --register mapgen

end

--!@}

spawning.register_spawn_algorithm("in_air1", mobf_spawn_in_air1)
spawning.register_spawn_algorithm("in_air1_spawner", mobf_spawn_in_air1_spawner,spawning.register_cleanup_spawner)