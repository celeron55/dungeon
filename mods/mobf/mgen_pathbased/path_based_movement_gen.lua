-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file path_based_movement_gen.lua
--! @brief component containing a path based movement generator (NOT COMPLETED)
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--
--! @defgroup mgen_path_based MGEN: Path based movement generator (NOT COMPLETED)
--! @ingroup framework_int
--! @{ 
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

--! @class p_mov_gen
--! @brief a movement generator evaluating a path to a target and following it
p_mov_gen = {}

--!@}

--! @brief movement generator identifier
--! @memberof p_mov_gen
p_mov_gen.name = "mgen_path"

-------------------------------------------------------------------------------
-- name: validate_position(current_pos,origin,destination)
--
--! @brief check if current position is on movement path to destination
--! @memberof p_mov_gen
--! @private
--
--! @param current_pos
--! @param origin of movement
--! @param destination of movement
-------------------------------------------------------------------------------
function p_mov_gen.validate_path_position(current_pos,origin,destination)



end

-------------------------------------------------------------------------------
-- name: validate_position(current_pos,origin,destination)
--
--! @brief check if there's a direct path from pos1 to pos2 for this mob
--! @memberof p_mov_gen
--! @private
--
-- param1: mob to check
-- param2: position1
-- param3: position2
-- retval: -
-------------------------------------------------------------------------------
function p_mov_gen.direct_path_available(entity,pos1,pos2)



end

-------------------------------------------------------------------------------
-- name: find_destination(entity,current_pos)
--
--! @brief find a suitable destination for this mob
--! @memberof p_mov_gen
--! @private
--
-- param1: mob to get destination for
-- param2: current position
-- retval: -
-------------------------------------------------------------------------------
function p_mov_gen.find_destination(entity,current_pos)

	--TODO
end

-------------------------------------------------------------------------------
-- name: set_speed(entity,destination)
--
--! brief set speed to destination for an mob
--! @memberof p_mov_gen
--! @private
--
-- param1: mob to get destination for
-- param2: destination of mob
-- retval: -
-------------------------------------------------------------------------------
function p_mov_gen.set_speed(entity,destination)


end

-------------------------------------------------------------------------------
-- name: fix_position(entity,current_pos)
--
--! @brief check if mob is in a valid position and fix it if necessary
--! @memberof p_mov_gen
--! @private
--
-- param1: mob to get destination for
-- param2: position of mob
-- retval: -
-------------------------------------------------------------------------------
function p_mov_gen.fix_position(entity,current_pos)


end

-------------------------------------------------------------------------------
-- name: update_movement(entity,now)
--
--! @brief check and update current movement state
--! @memberof p_mov_gen
--! @private
--
-- param1: mob to move
-- param2: current time
-- retval: -
-------------------------------------------------------------------------------
function p_mov_gen.update_movement(entity,now)

	--position of base block (different from center for ground based mobs)
	local pos 			= entity.getbasepos(entity)
	local centerpos     = entity.object:getpos()
	
	
	--validate current position for mob
	p_mov_gen.fix_position(entity,pos)
	
	--validate position is on path	
	if p_mov_gen.validate_path_position(pos,
						entity.dynamic_data.p_movement.origin,
						entity.dynamic_data.p_movement.destination)
						== false then
						
		--validate target is reachable
		if p_mov_gen.direct_path_available(entity,pos,entity.dynamic_data.p_movement.destination) then
		
			--set new direction to target
			 p_mov_gen.set_speed(entity,dynamic_data.p_movement.destination)
		else -- get new destination
			dynamic_data.p_movement.destination = p_mov_gen.find_destination(entity,pos)
			
			if dynamic_data.p_movement.destination ~= nil then
				p_mov_gen.set_speed(entity,dynamic_data.p_movement.destination)
			else
				mobf_bug_warning(LOGLEVEL_ERROR,"MOBF: BUG !!! unable to find a destination for an mob!")
			end
		end			
	end
end


-------------------------------------------------------------------------------
-- name: callback(entity,now)
--
--! @brief path based movement generator callback
--! @memberof p_mov_gen
--
-- param1: mob to do movement
-- param2: current time
-- retval: -
-------------------------------------------------------------------------------
function p_mov_gen.callback(entity,now)

	-- mob is in movement do movement handling
	if entity.dynamic_data.p_movement.in_movement then
		p_mov_gen.update_movement(entity,now)
	
	else
	-- calculate start movement chance	
	--TODO
	end
end


-------------------------------------------------------------------------------
-- name: init_dynamic_data(entity,now)
--
-- @brief initialize dynamic data required by movement generator
--! @memberof p_mov_gen
--
-- param1: entity to initialize
-- param2: current time
-- retval: -
-------------------------------------------------------------------------------
function p_mov_gen.init_dynamic_data(entity,now)

	local pos = entity.object:getpos()

	local data = {
			origin              = pos,
			targetlist			= nil,
			eta                 = nil,
			last_move_stop      = now,
			in_movement         = false
			}
	
	entity.dynamic_data.p_movement = data
end