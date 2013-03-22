-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file fighting.lua
--! @brief component for fighting related features
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--
--! @defgroup fighting Combat subcomponent
--! @brief Component handling all fighting
--! @ingroup framework_int
--! @{
-- Contact: sapier a t gmx net
-------------------------------------------------------------------------------

--! @class fighting

--! @brief factor added to mob melee combat range to get its maximum agression radius
MOBF_AGRESSION_FACTOR = 5

--!@}

--! @brief fighting class reference
fighting = {}

--! @brief user defined on death callback
--! @memberof fighting
fighting.on_death_callbacks = {}

-------------------------------------------------------------------------------
-- name: register_on_death_callback(callback)
--
--! @brief register an additional callback to be called on death of a mob
--! @memberof fighting
--
--! @param callback function to call
--! @return true/false
-------------------------------------------------------------------------------
function fighting.register_on_death_callback(callback)

	if type(callback) == "function" then
	
		table.insert(fighting.on_death_callbacks,callback)
		return true
	end
	return false
end

-------------------------------------------------------------------------------
-- name: do_on_death_callback(entity,hitter)
--
--! @brief call all registred on_death callbacks
--! @memberof fighting
--
--! @param entity to do callback for
--! @param hitter object doing last punch
-------------------------------------------------------------------------------
function fighting.do_on_death_callback(entity,hitter)

	for i,v in ipairs(fighting.on_death_callbacks) do
		v(entity.data.name,entity.getbasepos(),hitter)
	end
end

-------------------------------------------------------------------------------
-- name: push_back(entity,player)
--
--! @brief move a mob backward if it's punched
--! @memberof fighting
--! @private
--
--! @param entity mobbeing punched
--! @param dir direction to push back
-------------------------------------------------------------------------------
function fighting.push_back(entity,dir)
	--get some base information
	local mob_pos = entity.object:getpos()
	local mob_basepos = entity.getbasepos(entity)
	local dir_rad = mobf_calc_yaw(dir.x,dir.z)
	local posdelta = mobf_calc_vector_components(dir_rad,0.5)
	
	--push back mob
	local new_pos = {
		x=mob_basepos.x + posdelta.x,
		y=mob_basepos.y,
		z=mob_basepos.z + posdelta.z
		}
		
	local pos_valid = environment.possible_pos(entity,new_pos)
	new_pos.y = mob_pos.y
	local line_of_sight = mobf_line_of_sight(mob_pos,new_pos)

	dbg_mobf.fighting_lvl2("MOBF: trying to punch mob from " .. printpos(mob_pos) 
		.. " to ".. printpos(new_pos))
	if 	pos_valid and line_of_sight then
		dbg_mobf.fighting_lvl2("MOBF: punching back ")
		entity.object:moveto(new_pos)
	else
		dbg_mobf.fighting_lvl2("MOBF: not punching mob: " .. dump(pos_valid) .. " " ..dump(line_of_sight))
	end
end


-------------------------------------------------------------------------------
-- name: hit(entity,player)
--
--! @brief handler for mob beeing hit
--! @memberof fighting
--
--! @param entity mob being hit
--! @param player player/object hitting the mob
-------------------------------------------------------------------------------
function fighting.hit(entity,player)

	if entity.data.generic.on_hit_callback ~= nil and
			entity.data.generic.on_hit_callback(entity,player) == true
		then
		dbg_mobf.fighting_lvl2("MOBF: ".. entity.data.name .. " custom on hit handler superseeds generic handling")
		return
	end
	
	--TODO calculate damage by players weapon
	--local damage = 1

	--dbg_mobf.fighting_lvl2("MOBF: ".. entity.data.name .. " about to take ".. damage .. " damage")
	--entity.dynamic_data.generic.health = entity.dynamic_data.generic.health	 - damage

	--entity.object:set_hp(entity.object:get_hp() - damage )
	

	--get some base information
	local mob_pos = entity.object:getpos()
	local mob_basepos = entity.getbasepos(entity)
	local playerpos = player:getpos()
	local dir = mobf_get_direction(playerpos,mob_basepos)
	
	--update mob orientation
	if entity.mode == "3d" then
		entity.object:setyaw(mobf_calc_yaw(dir.x,dir.z)+math.pi)
	else
		entity.object:setyaw(mobf_calc_yaw(dir.x,dir.z)-math.pi)
	end
	
	if entity.data.sound ~= nil then
		sound.play(mob_pos,entity.data.sound.hit);
	end
	
	fighting.push_back(entity,dir)

	-- make it die
	if entity.object:get_hp() < 1 then
	--if entity.dynamic_data.generic.health < 1 then
		local result = entity.data.generic.kill_result
		if type(entity.data.generic.kill_result) == "function" then
			result = entity.data.generic.kill_result()
		end
		
		
		--call on kill callback and superseed normal on kill handling
		if entity.data.generic.on_kill_callback == nil or
			entity.data.generic.on_kill_callback(entity,player) == false
			then
			
			if entity.data.sound ~= nil then
				sound.play(mob_pos,entity.data.sound.die);
			end
			
			if player:is_player() then 
				if type(result) == "table" then
					for i=1,#result, 1 do
						if player:get_inventory():room_for_item("main", result[i]) then
							player:get_inventory():add_item("main", result[i])
						end
					end
				else
					if player:get_inventory():room_for_item("main", result) then
						player:get_inventory():add_item("main", result)
					end
				end
			else
				--todo check if spawning a stack is possible
				minetest.env:add_item(mob_pos,result)
			end
			spawning.remove(entity, "killed")
		else
			dbg_mobf.fighting_lvl2("MOBF: ".. entity.data.name 
				.. " custom on kill handler superseeds generic handling")
		end
		
		return
	end

	--dbg_mobf.fighting_lvl2("MOBF: attack chance is ".. entity.data.combat.angryness)
	-- fight back
	if entity.data.combat ~= nil and
		entity.data.combat.angryness > 0 then
		dbg_mobf.fighting_lvl2("MOBF: mob with chance of fighting back attacked")
		--either the mob hasn't been attacked by now or a new player joined fight
		
		local playername = player.get_player_name(player)
		
		if entity.dynamic_data.combat.target ~= playername then
			dbg_mobf.fighting_lvl2("MOBF: new player started fight")
			--calculate chance of mob fighting back
			if math.random() < entity.data.combat.angryness then
					dbg_mobf.fighting_lvl2("MOBF: fighting back player "..playername)
					entity.dynamic_data.combat.target = playername
					
					fighting.switch_to_combat_state(entity,mobf_get_current_time(),player)
			end	
		end

	end

end
-------------------------------------------------------------------------------
-- name: switch_to_combat_state(entity,now,target) 
--
--! @brief switch to combat state
--! @memberof fighting
--! @private
--
--! @param entity mob to switch state
--! @param now current time in seconds
--! @param target the target to attack
-------------------------------------------------------------------------------
function fighting.switch_to_combat_state(entity,now,target)
	local combat_state = mob_state.get_state_by_name(entity,"combat")
	
	if target == nil then
		dbg_mobf.fighting_lvl2("MOBF: no target for combat state change specified")
		return
	end
	
	if combat_state == nil then
		dbg_mobf.fighting_lvl2("MOBF: no special combat state")
		return
	end
	
	dbg_mobf.fighting_lvl2("MOBF: switching to combat state")
	
	--make sure state is locked
	mob_state.lock(entity,true)

	--backup dynamic movement data
	local backup = entity.dynamic_data.movement
	backup.current_state = mob_state.get_state_by_name(entity,entity.dynamic_data.state.current)
	
	--switch state
	local newentity = mob_state.change_state(entity,combat_state)
	
	if newentity ~= nil then
		entity = newentity
	end
	
	--save old movement data to use on switching back
	entity.dynamic_data.movement.backup = backup
		
	--set target
	entity.dynamic_data.movement.target = target
	
	--make sure a fighting mob ain't teleporting to target
	entity.dynamic_data.movement.teleportsupport = false
	
	--make sure we do follow our target
	entity.dynamic_data.movement.guardspawnpoint = false
	
end

-------------------------------------------------------------------------------
-- name: restore_previous_state(entity,now) 
--
--! @brief restore default movement generator of mob
--! @memberof fighting
--! @private
--
--! @param entity mob to restore movement generator
--! @param now current time in seconds
-------------------------------------------------------------------------------
function fighting.restore_previous_state(entity,now)

	--check if ther is anything we can restore
	if entity.dynamic_data.movement.backup ~= nil then
		local backup = entity.dynamic_data.movement.backup
		
		local newentity = nil
		if backup.current_state ~= nil then
			newentity = mob_state.change_state(entity,backup.current_state)
		else
			minetest.log(LOGLEVEL_WARNING,"MOBF: unable to restore previous state switching to default")
			newentity = mob_state.change_state(entity,mob_state.get_state_by_name(entity,"default"))
		end
			
			
		if newentity ~= nil then
			entity = newentity
		end
		
		--restore old movement data
		entity.dynamic_data.movement = backup
		
		--make sure all remaining data is deleted
		entity.dynamic_data.movement.backup = nil
		entity.dynamic_data.movement.current_state = nil
	end
	
	--make sure state is unlocked
	mob_state.lock(entity,false)
end

-------------------------------------------------------------------------------
-- name: combat(entity,now) 
--
--! @brief periodic callback called to do mobs own combat related actions
--! @memberof fighting
--
--! @param entity mob to do action
--! @param now current time
-------------------------------------------------------------------------------
function fighting.combat(entity,now)
	
	--handle self destruct mobs
	if fighting.self_destruct_handler(entity,now) then
		return
	end	

	if entity.dynamic_data.combat ~= nil and
		entity.dynamic_data.combat.target ~= "" then		

		dbg_mobf.fighting_lvl1("MOBF: attacking player: "..entity.dynamic_data.combat.target)

		local player = minetest.env:get_player_by_name(entity.dynamic_data.combat.target)


		--check if target is still valid
		if player == nil then
			dbg_mobf.fighting_lvl3("MOBF: not a valid player")
			
			-- switch back to default movement gen
			fighting.restore_previous_state(entity,now)
			
			--there is no player by that name, stop attack
			entity.dynamic_data.combat.target = ""
			return
		end
		
		--calculate some basic data
		local mob_pos = entity.object:getpos()
		local playerpos = player:getpos()
		local distance = mobf_calc_distance(mob_pos,playerpos)
		
		fighting.self_destruct_trigger(entity,distance,now)

		--find out if player is next to mob
		if distance > entity.data.combat.melee.range * MOBF_AGRESSION_FACTOR then
			dbg_mobf.fighting_lvl2("MOBF: " .. entity.data.name .. " player >" 
				.. entity.dynamic_data.combat.target .. "< to far away " 
				.. distance .. " > " .. (entity.data.combat.melee.range * MOBF_AGRESSION_FACTOR ) 
				.. " stopping attack")
			
			--switch back to default movement gen
			fighting.restore_previous_state(entity,now)
			
			--there is no player by that name, stop attack
			entity.dynamic_data.combat.target = ""
			return
		end

		--is mob near enough for any attack attack?
		if  (entity.data.combat.melee == nil or
			distance > entity.data.combat.melee.range) and
			(entity.data.combat.distance == nil or 
			distance > entity.data.combat.distance.range) then
			
			if entity.data.combat.melee ~= nil or
				entity.data.combat.distance ~= nil then
				dbg_mobf.fighting_lvl2("MOBF: distance="..distance)
				
				
				if entity.data.combat.melee ~= nil then
					dbg_mobf.fighting_lvl2("MOBF: melee="..entity.data.combat.melee.range)
				end
				if  entity.data.combat.distance ~= nil then
					dbg_mobf.fighting_lvl2("MOBF: distance="..entity.data.combat.distance.range)
				end
			end
			return
		end

		if fighting.melee_attack_handler(entity,player,now,distance) == false then
			
			if fighting.distance_attack_handler(entity,playerpos,mob_pos,now,distance) then
	
				-- mob did an attack so give chance to stop attack

				local rand_value = math.random()								

				if  rand_value > entity.data.combat.angryness then
					dbg_mobf.fighting_lvl2("MOBF: rand=".. rand_value 
						.. " angryness=" .. entity.data.combat.angryness)
					dbg_mobf.fighting_lvl2("MOBF: " .. entity.data.name .. " " 
						.. now .. " random aborting attack at player "
						..entity.dynamic_data.combat.target)
					entity.dynamic_data.combat.target = ""
				end
			end		
		end
	end
		
	--fight against generic enemy "sun"
	fighting.sun_damage_handler(entity,now)
	

end

-------------------------------------------------------------------------------
-- name: get_target(entity)
--
--! @brief find and possible target next to mob
--! @memberof fighting
--! @private
--
--! @param entity mob to look around
--! @return target
-------------------------------------------------------------------------------
function fighting.get_target(entity)

	local possible_targets = {}

	if entity.data.combat.melee.range > 0 then
		local objectlist = minetest.env:get_objects_inside_radius(entity.object:getpos(),
								entity.data.combat.melee.range*MOBF_AGRESSION_FACTOR)

		local count = 0

		for i,v in ipairs(objectlist) do
		
			local playername = v.get_player_name(v)			
	
			if playername ~= nil and
				playername ~= "" then
				count = count + 1
				table.insert(possible_targets,v)
				dbg_mobf.fighting_lvl3(playername .. " is next to a mob of type "
					.. entity.data.name);
			end

		end
		dbg_mobf.fighting_lvl3("Found ".. count .. " objects within attack range of "
			.. entity.data.name)
	end


	local targets_within_sight = {}

	for i,v in ipairs(possible_targets) do

		local entity_pos = entity.object:getpos()
		local target_pos = v:getpos()

		--is there a line of sight between mob and possible target
		--line of sight is calculated 1block above ground
		if mobf_line_of_sight({x=entity_pos.x,y=entity_pos.y+1,z=entity_pos.z},
					 {x=target_pos.x,y=target_pos.y+1,z=target_pos.z}) then

			table.insert(targets_within_sight,v)
		end

	end

	local nearest_target = nil
	local min_distance = -1

	for i,v in ipairs(targets_within_sight) do

		local distance = mobf_calc_distance(entity.object:getpos(),v:getpos())

		if min_distance < 0 or
			distance < min_distance then

			nearest_target = v
			min_distance = distance
		end
		
	end

	return nearest_target

end


-------------------------------------------------------------------------------
-- name: aggression(entity) 
--
--! @brief start attack in case of agressive mob
--! @memberof fighting
--
--! @param entity mob to do action
--! @param now current time
-------------------------------------------------------------------------------
function fighting.aggression(entity,now)

	--if no combat data is specified don't do anything
	if entity.data.combat == nil then
		return
	end

	--mob is specified as self attacking
	if entity.data.combat.starts_attack and 
		(entity.dynamic_data.combat.target == nil or
		entity.dynamic_data.combat.target == "") then
		dbg_mobf.fighting_lvl3("MOBF: ".. entity.data.name .. " " .. now
			.. " aggressive mob, is it time to attack?")
		if entity.dynamic_data.combat.ts_last_aggression_chance + 1 < now then
			dbg_mobf.fighting_lvl3("MOBF: ".. entity.data.name .. " " .. now
				.. " lazzy time over try to find an enemy")
			entity.dynamic_data.combat.ts_last_aggression_chance = now

			if math.random() < entity.data.combat.angryness then

				dbg_mobf.fighting_lvl3("MOBF: ".. entity.data.name .. " " .. now
					.. " really is angry")
				local target = fighting.get_target(entity)
				
				if target ~= nil then
					local targetname = target.get_player_name(target)

					if targetname ~= entity.dynamic_data.combat.target then

						entity.dynamic_data.combat.target = targetname		
						
						fighting.switch_to_combat_state(entity,now,target)			
						
						dbg_mobf.fighting_lvl2("MOBF: ".. entity.data.name .. " "
							.. now .. " starting attack at player: " ..targetname)
						minetest.log(LOGLEVEL_INFO,"MOBF: starting attack at player "..targetname)
					end
				end
			end
		end
	end
end

-------------------------------------------------------------------------------
-- name: fighting.init_dynamic_data(entity) 
--
--! @brief initialize all dynamic data on activate
--! @memberof fighting
--
--! @param entity mob to do action
--! @param now current time
-------------------------------------------------------------------------------
function fighting.init_dynamic_data(entity,now)
	local targetstring = ""
	local data = {
		ts_last_sun_damage			= now,
		ts_last_attack     			= now,
		ts_last_aggression_chance 	= now,
		ts_self_destruct_triggered  = -1,
		
		target             = targetstring,
	}	
	
	entity.dynamic_data.combat = data
end

-------------------------------------------------------------------------------
-- name: self_destruct_trigger(entity,distance) 
--
--! @brief handle self destruct features
--! @memberof fighting
--! @private
--
--! @param entity mob to do action
--! @param distance current distance to target
--! @param now current time
--! @return true/false if handled or not
-------------------------------------------------------------------------------
function fighting.self_destruct_trigger(entity,distance,now)
		if entity.data.combat ~= nil and
		   entity.data.combat.self_destruct ~= nil then

			dbg_mobf.fighting_lvl1("MOBF: checking for self destruct trigger " ..  
									distance .. " " .. 
									entity.dynamic_data.combat.ts_self_destruct_triggered .. 
									" " .. now)

			--trigger self destruct			
			if distance <= entity.data.combat.self_destruct.range and
				entity.dynamic_data.combat.ts_self_destruct_triggered == -1 then
				dbg_mobf.fighting_lvl2("MOBF: self destruct triggered")
				entity.dynamic_data.combat.ts_self_destruct_triggered = now
			end
		end
end
-------------------------------------------------------------------------------
-- name: self_destruct_handler(entity) 
--
--! @brief handle self destruct features
--! @memberof fighting
--! @private
--
--! @param entity mob to do action
--! @param now current time
--! @return true/false if handled or not
-------------------------------------------------------------------------------
function fighting.self_destruct_handler(entity,now)
		--self destructing mob?
		if entity.data.combat ~= nil and
		   entity.data.combat.self_destruct ~= nil then
		   

		   
		   local pos = entity.object:getpos()

			dbg_mobf.fighting_lvl1("MOBF: checking for self destruct imminent")
			--do self destruct
			if 	entity.dynamic_data.combat.ts_self_destruct_triggered > 0 and
				entity.dynamic_data.combat.ts_self_destruct_triggered + 
				entity.data.combat.self_destruct.delay
				<= now then
				
				dbg_mobf.fighting_lvl2("MOBF: executing self destruct")
				
				if entity.data.sound ~= nil then		
					sound.play(pos,entity.data.sound.self_destruct);		
				end
				
				mobf_do_area_damage(pos,nil,
										entity.data.combat.self_destruct.damage,
										entity.data.combat.self_destruct.range)

				--TODO determine block removal by damage and remove blocks
				mobf_do_node_damage(pos,{},
								entity.data.combat.self_destruct.node_damage_range,
								1 - 1/entity.data.combat.self_destruct.node_damage_range)
								
				if mobf_rtd.fire_enabled then
					--Add fire
					for i=pos.x-entity.data.combat.self_destruct.range/2, 
							pos.x+entity.data.combat.self_destruct.range/2, 1 do
					for j=pos.y-entity.data.combat.self_destruct.range/2, 
							pos.y+entity.data.combat.self_destruct.range/2, 1 do
					for k=pos.z-entity.data.combat.self_destruct.range/2, 
							pos.z+entity.data.combat.self_destruct.range/2, 1 do
					
						local current = minetest.env:get_node({x=i,y=j,z=k})
						
						if (current.name == "air") then
							minetest.env:set_node({x=i,y=j,z=k}, {name="fire:basic_flame"})
						end
					
					end
					end
					end	
				else
					minetest.log(LOGLEVEL_NOTICE,"MOBF: self destruct without fire isn't really impressive!")
				end
				spawning.remove(entity, "self destruct")
				return true
			end
		end
		return false
end

-------------------------------------------------------------------------------
-- name: melee_attack_handler(entity,now) 
--
--! @brief handle melee attack
--! @memberof fighting
--! @private
--
--! @param entity mob to do action
--! @param player player to attack
--! @param now current time
--! @param distance distance to player
--! @return true/false if handled or not
-------------------------------------------------------------------------------
function fighting.melee_attack_handler(entity,player,now,distance)

		if entity.data.combat.melee == nil then
			dbg_mobf.fighting_lvl2("MOBF: no meele attack specified")
			return false
		end

		local time_of_next_attack_chance = entity.dynamic_data.combat.ts_last_attack 
												+ entity.data.combat.melee.speed
		--check if mob is ready to attack
		if now <  time_of_next_attack_chance then
			dbg_mobf.fighting_lvl1("MOBF: to early for meele attack " .. 
									now .. " >= " .. time_of_next_attack_chance)
			return false
		end
		
		if distance <= entity.data.combat.melee.range
			then

			--save time of attack
			entity.dynamic_data.combat.ts_last_attack = now
			
			if entity.data.sound ~= nil then		
				sound.play(entity.object:getpos(),entity.data.sound.melee);		
			end

			--calculate damage to be done
			local damage_done = math.floor(math.random(0,entity.data.combat.melee.maxdamage)) + 1

			local player_health = player:get_hp()

			--do damage
			player:set_hp(player_health -damage_done)

			dbg_mobf.fighting_lvl2("MOBF: ".. entity.data.name .. 
									" doing melee attack damage=" .. damage_done)
			return true
		end
		dbg_mobf.fighting_lvl1("MOBF: not within meele range " .. 
									distance .. " > " .. entity.data.combat.melee.range) 
		return false
end


-------------------------------------------------------------------------------
-- name: distance_attack_handler(entity,now) 
--
--! @brief handle distance attack
--! @memberof fighting
--! @private
--
--! @param entity mob to do action
--! @param playerpos position of target
--! @param mob_pos position of mob
--! @param now current time
--! @param distance distance between target and player
--! @return true/false if handled or not
-------------------------------------------------------------------------------
function fighting.distance_attack_handler(entity,playerpos,mob_pos,now,distance)
		if 	entity.data.combat.distance == nil then
			dbg_mobf.fighting_lvl2("MOBF: no distance attack specified")
			return false
		end
		
		local time_of_next_attack_chance = entity.dynamic_data.combat.ts_last_attack 
											+ entity.data.combat.distance.speed

		--check if mob is ready to attack
		if 	now < time_of_next_attack_chance then
			dbg_mobf.fighting_lvl1("MOBF: to early for distance attack " .. 
									now .. " >= " .. time_of_next_attack_chance)	
			return false
		end
		
		if	distance <= entity.data.combat.distance.range
			then
			
			dbg_mobf.fighting_lvl2("MOBF: ".. entity.data.name .. " doing distance attack")
			
			--save time of attack
			entity.dynamic_data.combat.ts_last_attack = now
			
			local dir = mobf_get_direction({	x=mob_pos.x,
												y=mob_pos.y+1,
												z=mob_pos.z
												},
												playerpos)
												
			if entity.data.sound ~= nil then		
				sound.play(mob_pos,entity.data.sound.distance);		
			end
				
			local newobject=minetest.env:add_entity({	x=mob_pos.x+dir.x,
														y=mob_pos.y+dir.y+1,
														z=mob_pos.z+dir.z
														},
														entity.data.combat.distance.attack
														)

			local thrown_entity = mobf_find_entity(newobject)

			--TODO add random disturbance based on accuracy

			if thrown_entity ~= nil then
				local vel_trown = {
									x=dir.x*thrown_entity.velocity,
									y=dir.y*thrown_entity.velocity + math.random(0,0.25),
									z=dir.z*thrown_entity.velocity
									}
	
				dbg_mobf.fighting_lvl2("MOBF: throwing with velocity: " .. printpos(vel_trown))
	
				newobject:setvelocity(vel_trown)
	
				newobject:setacceleration({x=0, y=-thrown_entity.gravity, z=0})
				thrown_entity.owner = entity.object
	
				dbg_mobf.fighting_lvl2("MOBF: distance attack issued")
			else
				minetest.log(LOGLEVEL_ERROR, "MOBF: unable to find entity for distance attack")
			end
			return true
		end
		dbg_mobf.fighting_lvl1("MOBF: not within distance range " .. 
								distance .. " > " .. entity.data.combat.distance.range) 
		return false
end


-------------------------------------------------------------------------------
-- name: sun_damage_handler(entity,now) 
--
--! @brief handle damage done by sun
--! @memberof fighting
--! @private
--
--! @param entity mob to do action
--! @param now current time
-------------------------------------------------------------------------------
function fighting.sun_damage_handler(entity,now)
	if entity.data.combat ~= nil and
		entity.data.combat.sun_sensitive then

		local pos = entity.object:getpos()
		local current_state = mob_state.get_state_by_name(entity,entity.dynamic_data.state.current)
		local current_light = minetest.env:get_node_light(pos)
			
		if current_light == nil then
			minetest.log(LOGLEVEL_ERROR,"MOBF: Bug!!! didn't get a light value for "
				.. printpos(pos))
			return
		end
		--check if mob is in sunlight
		if ( current_light > LIGHT_MAX) then
			dbg_mobf.fighting_lvl1("MOBF: " .. entity.data.name .. 
										" health at start:" .. entity.object:get_hp())
			
			if current_state.animation ~= nil and 
				entity.data.animation ~= nil and
				entity.data.animation[current_state.animation .. "__burning"] ~= nil then
				graphics.set_animation(entity,current_state.animation .. "burning")
			else
				graphics.set_animation(entity,"burning")
			end
			
				
			if entity.dynamic_data.combat.ts_last_sun_damage +1 < now then
				local damage = (1 + math.floor(entity.data.generic.base_health/15))
				dbg_mobf.fighting_lvl1("Mob ".. entity.data.name .. " takes " 
					..damage .." damage because of sun")
				
				entity.object:set_hp(entity.object:get_hp() - damage)
				
				if entity.data.sound ~= nil then		
					sound.play(mob_pos,entity.data.sound.sun_damage);		
				end

				if entity.object:get_hp() <= 0 then
				--if entity.dynamic_data.generic.health <= 0 then
					dbg_mobf.fighting_lvl2("Mob ".. entity.data.name .. " died of sun")
					spawning.remove(entity,"died by sun")
					return
				end
				entity.dynamic_data.combat.ts_last_sun_damage = now
			end
		else
			--use last sun damage to avoid setting animation over and over even if nothing changed
			if entity.dynamic_data.combat.ts_last_sun_damage ~= -1 and
				current_state.animation ~= nil then
				graphics.set_animation(entity,current_state.animation)
				entity.dynamic_data.combat.ts_last_sun_damage = -1
			end
		end
	end
end