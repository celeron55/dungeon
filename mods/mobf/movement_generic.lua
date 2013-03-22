-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file movement_generic.lua
--! @brief generic movement related functions
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--
--! @defgroup generic_movement Generic movement functions
--! @brief Movement related functions used by different movement generators
--! @ingroup framework_int
--! @{
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

movement_generic = {}

--!@}

-------------------------------------------------------------------------------
-- name: get_accel_to(new_pos,entity) 
--
--! @brief calculate a random speed directed to new_pos
--
--! @param new_pos position to go to
--! @param entity mob to move
--! @return { x,y,z } random speed directed to new_pos
-------------------------------------------------------------------------------
--
function movement_generic.get_accel_to(new_pos,entity)

	if new_pos == nil or entity == nil then
		minetest.log(LOGLEVEL_CRITICAL,"MOBF: movement_generic.get_accel_to : Invalid parameters")
	end
	
	local old_pos  = entity.object:getpos()
	local node 	   = minetest.env:get_node(old_pos)
	local maxaccel = entity.data.movement.max_accel
	local minaccel = entity.data.movement.min_accel
	
	local yaccel = environment.get_default_gravity(old_pos,
							entity.environment.media,
							entity.data.movement.canfly)
	mobf_assert_backtrace(yaccel ~= nil)

	-- calc y speed for flying mobs
	local x_diff = new_pos.x - old_pos.x
	local z_diff = new_pos.z - old_pos.z

	local rand_x = (math.random() * (maxaccel - minaccel)) + minaccel
	local rand_z = (math.random() * (maxaccel - minaccel)) + minaccel

	if x_diff < 0 then
		rand_x = rand_x * -1
	end

	if z_diff < 0 then
		rand_z = rand_z * -1
	end

	return { x=rand_x,y=yaccel,z=rand_z }
end



-------------------------------------------------------------------------------
-- name: calc_new_pos(pos,acceleration,prediction_time)
--
--! @brief calc the position a mob would be after a specified time
--         this doesn't handle velocity changes due to colisions
--
--! @param pos position
--! @param acceleration acceleration to predict pos
--! @param prediction_time time to predict pos
--! @param current_velocity current velocity of mob
--! @return { x,y,z } position after specified time
-------------------------------------------------------------------------------
function movement_generic.calc_new_pos(pos,acceleration,prediction_time,current_velocity)	

	local predicted_pos = {x=pos.x,y=pos.y,z=pos.z}

	predicted_pos.x = predicted_pos.x + current_velocity.x * prediction_time + (acceleration.x/2)*math.pow(prediction_time,2)
	predicted_pos.z = predicted_pos.z + current_velocity.z * prediction_time + (acceleration.z/2)*math.pow(prediction_time,2)


	return predicted_pos
end

-------------------------------------------------------------------------------
-- name: predict_next_block(pos,velocity,acceleration)
--
--! @brief predict next block based on pos velocity and acceleration
--
--! @param pos current position
--! @param velocity current velocity
--! @param acceleration current acceleration
--! @return { x,y,z } position of next block
-------------------------------------------------------------------------------
function movement_generic.predict_next_block(pos,velocity,acceleration)

	local prediction_time = 2

	local pos_predicted = movement_generic.calc_new_pos(pos,
								acceleration,
								prediction_time,
								velocity
								)
	local count = 1

	--check if after prediction time we would have traveled more than one block and adjust to not predict to far
	while mobf_calc_distance(pos,pos_predicted) > 1 do		
	
		pos_predicted = movement_generic.calc_new_pos(pos,
								acceleration,
								prediction_time - (count*0.1),
								velocity
								)

		if (prediction_time - (count*0.1)) < 0 then
			minetest.log(LOGLEVEL_WARNING,"MOBF: Bug!!!! didn't find a suitable prediction time. Mob will move more than one block within prediction period")
			break
		end

		count = count +1
	end
	
	return pos_predicted
end