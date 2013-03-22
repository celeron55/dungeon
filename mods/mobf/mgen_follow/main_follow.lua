-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file main_follow.lua
--! @brief component containing a targeted movement generator
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--
--! @defgroup mgen_follow MGEN: follow movement generator
--! @brief A movement generator creating movement that trys to follow a moving 
--! target or reach a given point on map
--! @ingroup framework_int
--! @{ 
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

--! @class mgen_follow
--! @brief a movement generator trying to follow or reach a target
mgen_follow = {}

--!@}

--! @brief movement generator identifier
--! @memberof mgen_follow
mgen_follow.name = "follow_mov_gen"

-------------------------------------------------------------------------------
-- name: identify_movement_state(ownpos,targetpos)
--
--! @brief check what situation we are
--! @memberof mgen_follow
--
--! @param ownpos position of entity
--! @param targetpos position of target
--!
--! @return  "below_los"
--!          "below_no_los"
--!          "same_height_los"
--!          "same_height_no_los"
--!          "above_los"
--!          "above_no_los"
--!          "unknown"
-------------------------------------------------------------------------------
function mgen_follow.identify_movement_state(ownpos,targetpos)
	local same_height_delta = 0.1
	
	local los = mobf_line_of_sight(ownpos,targetpos)
	
	if ownpos.y > targetpos.y - same_height_delta and
		ownpos.y < targetpos.y + same_height_delta then
		
		if los then
			return "same_height_los"
		else
			return "same_height_no_los"
		end
	end
	
	if ownpos.y < targetpos.y then
		if los then
			return "below_los"
		else
			return "below_no_los"
		end
	end

	if ownpos.y > targetpos.y then
		if los then
			return "above_los"
		else
			return "above_no_los"
		end
	end
	
	return "unknown"
end

-------------------------------------------------------------------------------
-- name: handleteleport(entity,now)
--
--! @brief handle teleportsupport
--! @memberof mgen_follow
--
--! @param entity mob to check for teleport
--! @param now current time
--! @param targetpos position of target
--!
--! @return true/false finish processing
-------------------------------------------------------------------------------
function mgen_follow.handleteleport(entity,now,targetpos)

	if (entity.dynamic_data.movement.last_next_to_target ~= nil ) then
		local time_since_next_to_target =
			now - entity.dynamic_data.movement.last_next_to_target
			
		dbg_mobf.fmovement_lvl3("MOBF:   time since next to target: " .. time_since_next_to_target .. 
									" delay: " .. dump(entity.data.movement.teleportdelay) ..
									" teleportsupport: " .. dump(entity.dynamic_data.movement.teleportsupport))

		if (entity.dynamic_data.movement.teleportsupport) and
			time_since_next_to_target > entity.data.movement.teleportdelay then

			entity.object:setvelocity({x=0,y=0,z=0})
			entity.object:setacceleration({x=0,y=0,z=0})
			entity.object:moveto(targetpos)
			entity.dynamic_data.movement.last_next_to_target = now
			return true
		end
	end
	return false
end

-------------------------------------------------------------------------------
-- name: callback(entity,now)
--
--! @brief main callback to make a mob follow its target
--! @memberof mgen_follow
--
--! @param entity mob to generate movement for
--! @param now current time
-------------------------------------------------------------------------------
function mgen_follow.callback(entity,now)

	dbg_mobf.fmovement_lvl3("MOBF: Follow mgen callback called")
	

	
	if entity == nil then
		mobf_bug_warning(LOGLEVEL_ERROR,"MOBF BUG!!!: called movement gen without entity!")
		return
	end
	
	if entity.dynamic_data == nil or
		entity.dynamic_data.movement == nil then
		mobf_bug_warning(LOGLEVEL_ERROR,"MOBF BUG!!!: >" ..entity.data.name .. "< removed=" .. dump(entity.removed) .. " entity=" .. tostring(entity) .. " probab movement callback")
		return
	end
	
	local follow_speedup = 10
	
	if entity.data.movement.follow_speedup ~= nil then
		follow_speedup = entity.data.movement.follow_speedup
	end
	
	--check max speed limit
	mgen_follow.checkspeed(entity)
	
	
	--check environment
	local basepos  = entity.getbasepos(entity)
	local state = environment.pos_is_ok(basepos,entity)
	
	if state == "ok" then
		local toset = {
			x= basepos.x,
			y= basepos.y - 0.5 - entity.collisionbox[2],
			z= basepos.z }
		--save known good position
		entity.dynamic_data.movement.last_pos_in_env = toset
	end
	
	if not environment.possible_pos(entity,basepos) or 
		state == "in_water" or 
		state == "above_water" or
		state == "in_air" or
		state == "drop_above_water" then
		dbg_mobf.fmovement_lvl1("MOBF: followed to wrong place " .. state)
		if entity.dynamic_data.movement.last_pos_in_env ~= nil then
			entity.object:moveto(entity.dynamic_data.movement.last_pos_in_env)
			basepos  = entity.getbasepos(entity)
		else
			local newpos = environment.get_suitable_pos_same_level(basepos,1,entity,true)
			
			if newpos == nil then
				spawning.remove(entity,"mgen_follow poscheck")
			else
				newpos.y = newpos.y - (entity.collisionbox[2] + 0.49)
				entity.object:moveto(newpos)
				basepos  = entity.getbasepos(entity)
			end
		end
	end
	
	if entity.dynamic_data.movement.target ~= nil or
		entity.dynamic_data.movement.guardspawnpoint then
		dbg_mobf.fmovement_lvl3("MOBF:   Target available")
		--calculate distance to target
		local targetpos = entity.dynamic_data.spawning.spawnpoint
		
		
		if entity.dynamic_data.movement.guardspawnpoint ~= true then
			dbg_mobf.fmovement_lvl3("MOBF:   moving target selected")
			targetpos = entity.dynamic_data.movement.target:getpos()
		end
		
		if targetpos == nil then
			minetest.log(LOGLEVEL_ERROR,"MOBF: " .. entity.data.name 
			.. " don't have targetpos " 
			.. "SP: " .. dump(entity.dynamic_data.spawning.spawnpoint)
			.. " TGT: " .. dump(entity.dynamic_data.movement.target))
			return
		end
		
		local distance = mobf_calc_distance_2d(basepos,targetpos)
		
		local yaccel = environment.get_default_gravity(basepos,
							entity.environment.media,
							entity.data.movement.canfly)
		dbg_mobf.fmovement_lvl3("MOBF:   default gravity is " .. yaccel )
		
		if mobf_line_of_sight({x=basepos.x,y=basepos.y+1,z=basepos.z},
						 {x=targetpos.x,y=targetpos.y+1,z=targetpos.z})  == false then
			dbg_mobf.fmovement_lvl3("MOBF:   no line of sight")
			--TODO teleport support?
			--TODO other ways to handle this?
			--return						 
		end
		dbg_mobf.fmovement_lvl3("MOBF:   line of sight")
		
		local max_distance = entity.dynamic_data.movement.max_distance
		
		if max_distance == nil then
			max_distance = 1
		end
		
		--check if mob needs to move towards target
		dbg_mobf.fmovement_lvl3("MOBF: max distance is set to : " .. max_distance)
		if distance > max_distance then
		
			if mgen_follow.handleteleport(entity,now,targetpos) then
				return
			end

			dbg_mobf.fmovement_lvl3("MOBF:   distance:" .. distance)
			
			local current_state = mgen_follow.identify_movement_state(basepos,targetpos)
			local handled = false
			
			if handled == false and 
				(current_state == "same_height_los" or
				current_state == "above_los" or
				current_state == "above_no_los" ) then
				dbg_mobf.fmovement_lvl3("MOBF: \t Case 1: " .. current_state)
				local accel_to_set = movement_generic.get_accel_to(targetpos,entity)
				accel_to_set.y = yaccel
				dbg_mobf.fmovement_lvl3("MOBF:   setting acceleration to: " .. printpos(accel_to_set));
				mgen_follow.set_acceleration(entity,accel_to_set,follow_speedup)
				
				handled = true
			end
			
			if handled == false and
				(current_state == "below_los" or
				 current_state == "below_no_los" or
				 current_state == "same_height_no_los" ) then
				dbg_mobf.fmovement_lvl3("MOBF: \t Case 2: " .. current_state)
				local accel_to_set = movement_generic.get_accel_to(targetpos,entity)
				accel_to_set.y = yaccel
				
				local current_velocity = entity.object:getvelocity()
				local predicted_pos = movement_generic.predict_next_block(basepos,current_velocity,accel_to_set)
				local pos_state  = environment.pos_is_ok(predicted_pos,entity)
				
				if pos_state == "collision_jumpable" then			
					local pos_to_set = entity.object:getpos()
					pos_to_set.y = pos_to_set.y + 1.1
					entity.object:moveto(pos_to_set)
				end
				dbg_mobf.fmovement_lvl3("MOBF:   setting acceleration to: " 
					.. printpos(accel_to_set) .. " predicted_state: "
					.. pos_state);
				mgen_follow.set_acceleration(entity,accel_to_set,follow_speedup)
				
				handled = true
			end

			if handled == false then
				dbg_mobf.fmovement_lvl1("MOBF: \t Unexpected movement state: " .. current_state)
			end
		--nothing to do
		else
			dbg_mobf.fmovement_lvl3("MOBF:   next to target")
			entity.object:setvelocity({x=0,y=0,z=0})
			entity.object:setacceleration({x=0,y=0,z=0})
			entity.dynamic_data.movement.last_next_to_target = now
			
			
			local dir = mobf_get_direction(basepos,targetpos)
			--update mob orientation
			if entity.mode == "3d" then
				entity.object:setyaw(mobf_calc_yaw(dir.x,dir.z))
			else
				entity.object:setyaw(mobf_calc_yaw(dir.x,dir.z))
			end
		end
	
	else	
		--TODO evaluate if this is an error case	
	end
end


-------------------------------------------------------------------------------
-- name: initialize()
--
--! @brief initialize movement generator
--! @memberof mgen_follow
--! @public
-------------------------------------------------------------------------------
function mgen_follow.initialize(entity,now)
	--intentionally empty
end

-------------------------------------------------------------------------------
-- name: init_dynamic_data(entity,now)
--
--! @brief initialize dynamic data required by movement generator
--! @memberof mgen_follow
--! @public
--
--! @param entity mob to initialize dynamic data
--! @param now current time
-------------------------------------------------------------------------------
function mgen_follow.init_dynamic_data(entity,now)

	local pos = entity.object:getpos()


	local data = {
			target = nil,
			guardspawnpoint = false,
			max_distance = entity.data.movement.max_distance,
			orientation_fix_needed = true,
			}
	
	if entity.data.movement.guardspawnpoint ~= nil and
		entity.data.movement.guardspawnpoint then
			dbg_mobf.fmovement_lvl3("MOBF: setting guard point to: " .. printpos(entity.dynamic_data.spawning.spawnpoint))
			data.guardspawnpoint = true
		end
		
		if entity.data.movement.teleportdelay~= nil then
			data.last_next_to_target = now
			data.teleportsupport = true
		end
	
	entity.dynamic_data.movement = data
end

-------------------------------------------------------------------------------
-- name: checkspeed(entity)
--
--! @brief check if mobs speed is within it's limits and correct if necessary
--! @memberof mgen_follow
--! @private
--
--! @param entity mob to initialize dynamic data
-------------------------------------------------------------------------------
function mgen_follow.checkspeed(entity)

	local current_velocity = entity.object:getvelocity()

	local xzspeed = math.sqrt(math.pow(current_velocity.x,2)+
	                          math.pow(current_velocity.z,2))

	if (xzspeed > entity.data.movement.max_speed) then
	
		--preserver orientation when correcting speed
		local dir = mobf_calc_yaw(current_velocity.x,current_velocity.z)
		local velocity_to_set = mobf_calc_vector_components(dir,entity.data.movement.max_speed * 0.25)
	
		velocity_to_set.y=current_velocity.y
	
		entity.object:setvelocity(velocity_to_set)
		
		return true
	end
	
	return false
end

-------------------------------------------------------------------------------
-- name: set_acceleration(entity,accel,speedup)
--
--! @brief apply acceleration to entity
--! @memberof mgen_follow
--! @private
--
--! @param entity mob to apply to
--! @param accel acceleration to set
--! @param speedup speedup factor
-------------------------------------------------------------------------------
function mgen_follow.set_acceleration(entity,accel,speedup)
		entity.object:setacceleration({x=accel.x*speedup,
								   y=accel.y,
								   z=accel.z*speedup})
end


--register this movement generator
registerMovementGen(mgen_follow.name,mgen_follow)