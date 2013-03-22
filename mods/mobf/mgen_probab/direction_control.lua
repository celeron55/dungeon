-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file direction_control.lua
--! @brief functions for direction control in probabilistic movement gen
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--
--! @ingroup mgen_probab
--! @{ 
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

--! @class direction_control
--! @brief functions for direction control in probabilistic movement gen
direction_control = {}
--!@}

-------------------------------------------------------------------------------
-- name: changeaccel(pos,entity,velocity)
--
--! @brief find a suitable new acceleration for mob
--! @memberof direction_control
--! @private
--
--! @param pos current position
--! @param entity mob to get acceleration for
--! @param current_velocity current velocity
--! @return {{ x/y/z accel} + jump flag really?
-------------------------------------------------------------------------------
function direction_control.changeaccel(pos,entity,current_velocity)

	local new_accel = direction_control.get_random_acceleration(entity.data.movement.min_accel,
														entity.data.movement.max_accel,entity.object:getyaw(),0)

	local pos_predicted = movement_generic.predict_next_block(pos,current_velocity,new_accel)

	local maxtries = 5

	local state = environment.pos_is_ok(pos_predicted,entity)

	--below_limit and above_limit are ok too respective to movement handled by this component is xz only
	while  state ~= "ok" and
			state == "above_limit" and
			state == "below_limit"do
		dbg_mobf.pmovement_lvl1("MOBF: predicted pos " .. printpos(pos_predicted) .. " isn't ok " .. maxtries .. " tries left, state: " .. state)
		local done = false

		--don't loop forever get to save mode and try next time
		if maxtries <= 0 then
			dbg_mobf.pmovement_lvl1("MOBF: Aborting acceleration finding for this cycle due to max retries")
			if 	state == "collision_jumpable" then
				dbg_mobf.movement_lvl1("Returning "..printpos(new_accel).." as new accel as mob may jump")
				return new_accel
			end
		
			dbg_mobf.pmovement_lvl1("MOBF: Didn't find a suitable acceleration stopping movement: " .. entity.data.name .. printpos(pos))
			entity.object:setvelocity({x=0,y=0,z=0})
			entity.dynamic_data.movement.started = false
			--don't slow down mob
			return  {  x=0,
						y=0,
						z=0 }
		end
		
		--in case mob is already at non perfect surface it's not that bad to get on it again
		if not done and (state == "possible_surface") then
			local current_state = environment.pos_is_ok(pos,entity)
			local probab = math.random()
			
			if current_state == "wrong_surface" or
				current_state == "possible_surface" then
				if probab < 0.3 then
					done = true
				end
			else
				if probab < 0.05 then
					done = true
				end
			end
		end

		--first try to invert acceleration on collision
--		if not done and (state == "collision" or
--			state == "collision_jumpable") then
--			new_accel = { 	x= new_accel.x * -1,
--					y= new_accel.y,
--					z= new_accel.z * -1}

--			pos_predicted = movement_generic.predict_next_block(pos,current_velocity,new_accel)
--			if environment.pos_is_ok(pos_predicted,entity) == "ok" then
--				done = true
--			end

--		end

		--generic way to find new acceleration
		if not done then
			new_accel = direction_control.get_random_acceleration(entity.data.movement.min_accel,
														entity.data.movement.max_accel,entity.object:getyaw(),1.57)
		
			pos_predicted = movement_generic.predict_next_block(pos,current_velocity,new_accel)
		end

		state = environment.pos_is_ok(pos_predicted,entity)
		maxtries = maxtries -1
	end

	return new_accel

end

-------------------------------------------------------------------------------
-- name: get_random_acceleration(minaccel,maxaccel,current_yaw, minrotation)
--
--! @brief get a random x/z acceleration within a specified acceleration range
--! @memberof direction_control
--! @private
--
--! @param minaccel minimum acceleration to use
--! @param maxaccel maximum acceleration
--! @param current_yaw current orientation of mob
--! @param minrotation minimum rotation to perform
--! @return x/y/z acceleration
-------------------------------------------------------------------------------
function direction_control.get_random_acceleration(minaccel,maxaccel,current_yaw, minrotation)

	local direction = 1
	if math.random() < 0.5 then
		direction = -1
	end
	
	--calc random absolute value
	local rand_accel = (math.random() * (maxaccel - minaccel)) + minaccel

	local orientation_delta = 0

	--randomize direction
	for i=0, 100 do
	
		if math.random() < 0.2 then
			break
		end
		orientation_delta = orientation_delta +0.1
	end
	
	--calculate new acceleration
	
	
	local new_direction =  current_yaw + ((minrotation + orientation_delta) * direction)

	local new_accel = {
		x = math.sin(new_direction) *rand_accel,
		y = nil,
		z = math.cos(new_direction) *rand_accel
		}
		
	dbg_mobf.pmovement_lvl3(" new direction: " .. new_direction .. " old direction: " .. current_yaw .. " new accel: " .. printpos(new_accel))

	return new_accel
end



-------------------------------------------------------------------------------
-- name: precheck_movement(entity,movement_state)
--
--! @brief check if x/z movement results in invalid position and change
--         movement if required
--! @memberof direction_control
--
--! @param entity mob to generate movement
--! @param movement_state current state of movement
--! @param pos_predicted position mob will be next
--! @param pos_predicted_state suitability state of predicted position
--! @return movement_state is changed!
-------------------------------------------------------------------------------
function direction_control.precheck_movement(entity,movement_state,pos_predicted,pos_predicted_state)

	--next block mob is to be isn't a place where it can be so we need to change something
	if pos_predicted_state ~= "ok" and
		pos_predicted_state ~= "above_limit" and
		pos_predicted_state ~= "below_limit" then

		-- mob would walk onto water
		if movement_state.changed == false and 
			( pos_predicted_state == "above_water" or
			  pos_predicted_state == "drop" or
			  pos_predicted_state == "drop_above_water")
			then
			dbg_mobf.pmovement_lvl1("MOBF: mob " .. entity.data.name .. " is going to walk on water or drop")
			local new_pos = environment.get_suitable_pos_same_level(movement_state.basepos,1,entity)

			--try to find at least a possible position
			if new_pos == nil then
				dbg_mobf.pmovement_lvl1("MOBF: mob " .. entity.data.name .. " no prefect fitting position found")
				new_pos = environment.get_suitable_pos_same_level(movement_state.basepos,1,entity,true)
			end

			if new_pos ~= nil then
				dbg_mobf.pmovement_lvl2("MOBF: redirecting to safe position .. " .. printpos(new_pos))
				movement_state.accel_to_set = movement_generic.get_accel_to(new_pos,entity)
				pos_predicted = movement_generic.predict_next_block( movement_state.basepos,
																movement_state.current_velocity,
																movement_state.accel_to_set)
				pos_predicted_state = environment.pos_is_ok({x=pos_predicted.x,y=pos_predicted.y+1,z=pos_predicted.z},entity)
				for i=0,10,1 do
					if pos_predicted_state == "ok" or 
						pos_predicted_state == "possible_surface" then
						break
					end
					movement_state.accel_to_set = movement_generic.get_accel_to(new_pos,entity)
					pos_predicted = movement_generic.predict_next_block( movement_state.basepos,
																movement_state.current_velocity,
																movement_state.accel_to_set)
					pos_predicted_state = environment.pos_is_ok({x=pos_predicted.x,y=pos_predicted.y+1,z=pos_predicted.z},entity)
				end
				
				if pos_predicted_state == "ok" or 
						pos_predicted_state == "possible_surface" then
					dbg_mobf.pmovement_lvl1("MOBF: redirecting to safe position .. " .. printpos(new_pos) .. " failed!")
				end
				movement_state.changed = true
			else
				local current_state = environment.pos_is_ok(movement_state.basepos,entity)
				
				--animal is safe atm stop it to avoid doing silly things
				if current_state == "ok" or
					current_state == "possible_surface" then
					entity.object:setvelocity({x=0,y=0,z=0})
					movement_state.accel_to_set = {x=0,y=nil,z=0}
					movement_state.changed = true
					dbg_mobf.pmovement_lvl2("MOBF: couldn't find acceleration but mob is safe where it is") 
				else
					--apply random acceleration to avoid permanent stuck mobs maybe mobs should be deleted instead
					movement_state.accel_to_set = direction_control.get_random_acceleration(entity.data.movement.min_accel,
															entity.data.movement.max_accel,entity.object:getyaw(),0)
					movement_state.changed = true
					dbg_mobf.pmovement_lvl2("MOBF: couldn't find acceleration mob ain't safe either, just move on with random movement") 
				end
			end
		end

		if movement_state.changed == false and pos_predicted_state == "collision_jumpable" then
			dbg_mobf.movement_lvl1("mob is about to collide")
			if environment.pos_is_ok({x=pos_predicted.x,y=pos_predicted.y+1,z=pos_predicted.z},entity) == "ok" then
				if math.random() < ( entity.dynamic_data.movement.mpattern.jump_up * PER_SECOND_CORRECTION_FACTOR) then
					local node_at_predicted_pos = minetest.env:get_node(pos_predicted)
					dbg_mobf.pmovement_lvl2("MOBF: velocity is:" .. printpos(movement_state.current_velocity) .. " position is: "..printpos(pos) ) 
					dbg_mobf.pmovement_lvl2("MOBF: estimated position was: "..printpos(pos_predicted))
					dbg_mobf.pmovement_lvl2("MOBF: predicted node state is: " .. environment.pos_is_ok(pos_predicted,entity))
					--if node_at_predicted_pos ~= nil then
						--dbg_mobf.movement_lvl1("MOBF: jumping onto: " .. node_at_predicted_pos.name)
					--end
					movement_state.accel_to_set = { x=0,y=nil,z=0 }
					movement_state.changed = true
					
					--todo check if y pos is ok?!
					local jumppos = {x=pos_predicted.x,y=movement_state.centerpos.y+1,z=pos_predicted.z}
					
					dbg_mobf.pmovement_lvl2("MOBF: mob " ..entity.data.name .. " is jumping, moving to:" .. printpos(jumppos))
					dbg_mobf.pmovement_lvl2("MOBF: target pos node state is: " .. environment.pos_is_ok(jumppos,entity))
					
					entity.object:moveto(jumppos)
					--TODO set movement state positions
					--movement_state.basepos=
					--movement_state.centerpos=
				end
			end
		end

		--redirect mob to block thats not above its current level
		--or jump if possible
		if movement_state.changed == false and pos_predicted_state == "collision" then
			dbg_mobf.pmovement_lvl1("MOBF: mob is about to collide")

			local new_pos = environment.get_suitable_pos_same_level(movement_state.basepos,1,entity)
		
			--there is at least one direction to go
			if new_pos ~= nil then				
				movement_state.accel_to_set = movement_generic.get_accel_to(new_pos,entity)
				movement_state.changed = true
			
			else
				local jumppos = nil
				--there ain't any acceptable pos at same level try to find one above current position
				new_pos = environment.get_suitable_pos_same_level({ x=movement_state.basepos.x,
																		 y=movement_state.basepos.y+1,
																		 z=movement_state.basepos.z},
																		1,entity)
				
				if new_pos ~= nil then
					jumppos = {x=new_pos.x,y=movement_state.centerpos.y+1,z=new_pos.z}
				end
				
				--there ain't any acceptable pos at same level try to find one below current position
				new_pos = environment.get_suitable_pos_same_level({ x=movement_state.basepos.x,
																		 y=movement_state.basepos.y-1,
																		 z=movement_state.basepos.z},
																		1,entity)
				
				if new_pos ~= nil then
					jumppos = {x=new_pos.x,y=movement_state.centerpos.y-1,z=new_pos.z}
				end
				
				
				if jumppos ~= nil then
					dbg_mobf.pmovement_lvl2("MOBF: mob " ..entity.data.name .. " seems to be locked in, moving to:" .. printpos(jumppos))
					entity.object:moveto(jumppos)
					
					movement_state.accel_to_set = { x=0,y=nil,z=0 }
					movement_state.changed = true
				end				
			end
		end
		
		--generic try to solve situation eg wrong surface
		if movement_state.changed == false then
			dbg_mobf.pmovement_lvl1("MOBF: generic try to resolve state " .. pos_predicted_state .. " for mob " .. entity.data.name .. " "..printpos(movement_state.basepos))
			movement_state.accel_to_set = direction_control.changeaccel(movement_state.basepos,
										entity,movement_state.current_velocity)
			if movement_state.accel_to_set ~= nil then
				movement_state.changed = true	
			end
		end
	end
end

-------------------------------------------------------------------------------
-- name: random_movement_handler(entity,movement_state)
--
--! @brief generate a random y-movement
--! @memberof direction_control
--
--! @param entity mob to apply random jump
--! @param movement_state current movement state
--! @return movement_state is modified!
-------------------------------------------------------------------------------
function direction_control.random_movement_handler(entity,movement_state)
	dbg_mobf.pmovement_lvl1("MOBF: random movement handler called")
	if movement_state.changed == false and
		(math.random() < (entity.dynamic_data.movement.mpattern.random_acceleration_change * PER_SECOND_CORRECTION_FACTOR) or 
		movement_state.force_change) then

		movement_state.accel_to_set = direction_control.changeaccel(movement_state.basepos,
							entity,movement_state.current_velocity)
		if movement_state.accel_to_set ~= nil then
			--retain current y acceleration
			movement_state.accel_to_set.y = movement_state.current_acceleration.y
			movement_state.changed = true	
		end
		dbg_mobf.pmovement_lvl1("MOBF: randomly changing speed from "..printpos(movement_state.current_acceleration).." to "..printpos(movement_state.accel_to_set))
	end
end