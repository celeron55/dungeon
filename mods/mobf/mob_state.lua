-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file mob_state.lua
--! @brief component mob state transition handling
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--
--
--! @defgroup mob_state State handling functions
--! @brief a component to do basic changes to mob on state change
--! @ingroup framework_int
--! @{ 
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

mob_state = {}
mob_state.default_state_time = 30

-------------------------------------------------------------------------------
-- name: initialize(entity,now)
--
--! @brief initialize state dynamic data
--! @ingroup mob_state
--
--! @param entity elemet to initialize state data
--! @param now current time
-------------------------------------------------------------------------------
function mob_state.initialize(entity,now)

	dbg_mobf.mob_state_lvl3("MOBF: " .. entity.data.name 
		.. " initializing state dynamic data")
	
	local state = {
		current = "default",
		time_to_next_change = 30,
		locked = false,
		enabled = false,
	}
	
	local sum_chances = 0
	local state_count = 0
	
	if entity.data.states ~= nil then
		for s = 1, #entity.data.states , 1 do
			sum_chances = sum_chances + entity.data.states[s].chance
		
			if entity.data.states[s].name ~= "combat" and
				entity.data.states[s].name ~= "default" then
				state_count = state_count +1
			end
		end
	end
	
	--sanity check for state chances
	if sum_chances > 1 then
		minetest.log(LOGLEVEL_WARNING,"MOBF: Warning sum of state chances for mob " 
			.. entity.data.name .. " > 1")
	end
	
	--only enable state changeing if there is at least one state
	if state_count > 0 then
		state.enabled = true
	end

	entity.dynamic_data.state = state
end


-------------------------------------------------------------------------------
-- name: get_entity_name(mob,state)
--
--! @brief get entity name for a state
--! @ingroup mob_state
--
--! @param mob generic data
--! @param state selected state data
--!
--! @return name to use for entity
-------------------------------------------------------------------------------
function mob_state.get_entity_name(mob,state)
	return mob.modname .. ":"..mob.name .. "__" .. state.name
end

-------------------------------------------------------------------------------
-- name: get_state_by_name(entity,name)
--
--! @brief get a state by its name
--! @ingroup mob_state
--
--! @param entity elemet to look for state data
--! @param name of state
--!
--! @return state data or nil
-------------------------------------------------------------------------------
function mob_state.get_state_by_name(entity,name)
	mobf_assert_backtrace(entity ~= nil and entity.data ~= nil)

	for i=1, #entity.data.states, 1 do
		if entity.data.states[i].name == name then
			return entity.data.states[i]
		end
	end
	
	return nil
end

-------------------------------------------------------------------------------
-- name: lock(entity,value)
--
--! @brief disable random state changes for a mob
--! @ingroup mob_state
--
--! @param entity elemet to lock
--! @param value to set
-------------------------------------------------------------------------------
function mob_state.lock(entity,value)
	if value ~= false and value ~= true then
		return
	end
	if entity.dynamic_data.state == nil then
		dbg_mobf.mob_state_lvl1("MOBF: unable to lock state for: " 
			.. entity.data.name .. " no state dynamic data present")
		return 
	end
		
	entity.dynamic_data.state.locked = value
end


-------------------------------------------------------------------------------
-- name: callback(entity,now,dstep)
--
--! @brief callback handling state changes
--! @ingroup mob_state
--
--! @param entity elemet to look for state data
--! @param now current time
--! @param dstep time passed since last call
-------------------------------------------------------------------------------
function mob_state.callback(entity,now,dstep)

	if entity.dynamic_data.state == nil then
		minetest.log(LOGLEVEL_ERRROR,"MOBF BUG: " .. entity.data.name 
			.. " mob state callback without mob dynamic data!")
		mob_state.initialize(entity,now)
		local default_state = mob_state.get_state_by_name(self,"default")
		entity.dynamic_data.current_movement_gen = getMovementGen(default_state.movgen)
		entity.dynamic_data.current_movement_gen.init_dynamic_data(entity,mobf_get_current_time())
		entity = spawning.replace_entity(entity,entity.data.modname .. ":"..entity.data.name,true)
		return true
	end
	--abort state change if current state is locked
	if entity.dynamic_data.state.locked or 
		entity.dynamic_data.state.enabled == false then
		dbg_mobf.mob_state_lvl3("MOBF: " .. entity.data.name 
			.. " state locked or no custom states definded ")
		return true
	end
	
	entity.dynamic_data.state.time_to_next_change = entity.dynamic_data.state.time_to_next_change -dstep
	
	--do only change if last state timed out
	if entity.dynamic_data.state.time_to_next_change < 0 then
	
		dbg_mobf.mob_state_lvl2("MOBF: " .. entity.data.name 
			.. " time to change state: " .. entity.dynamic_data.state.time_to_next_change 
			.. " , " .. dstep .. " entity=" .. tostring(entity))
	
		local rand = math.random()
		
		local maxvalue = 0
		
		local state_table = {}
		
		--fill table with available states
		for i=1, #entity.data.states, 1 do
			if entity.data.states[i].custom_preconhandler == nil or
				entity.data.states[i].custom_preconhandler() then
				table.insert(state_table,entity.data.states[i])
			end
		end
		
		--try to get a random state to change to
		for i=1, #state_table, 1 do
			
			local rand_state = math.random(#state_table)
			local current_chance = 0
			
			if type (state_table[rand_state].chance) == "function" then
				current_chance = state_table[rand_state].chance(entity,now,dstep)
			else
				if state_table[rand_state].chance ~= nil then
					current_chance = state_table[rand_state].chance
				end
			end
			
			if math.random() < current_chance then
				if mob_state.change_state(entity,state_table[rand_state]) ~= nil then
					return false
				else
					return true
				end
			end
		end
		
		--switch to default state (only reached if no change has been done
		if mob_state.change_state(entity,mob_state.get_state_by_name(entity,"default")) ~= nil then
			return false
		end
	else
		dbg_mobf.mob_state_lvl3("MOBF: " .. entity.data.name 
			.. " is not ready for state change ")
		return true
	end
	
	return true
end

-------------------------------------------------------------------------------
-- name: switch_entity(entity,state)
--
--! @brief helper function to swich an entity based on new state
--! @ingroup mob_state
--
--! @param entity to replace
--! @param state to take new entity
--!
--! @return the new entity or nil
-------------------------------------------------------------------------------
function mob_state.switch_entity(entity,state)
	--switch entity
	local state_has_model = false
	
	if minetest.setting_getbool("mobf_disable_3d_mode") then
		if state.graphics ~= nil then
			state_has_model = true
		end
	else
		if state.graphics_3d ~= nil then
			state_has_model = true
		end
	end
	
	local newentity = nil
	
	if state_has_model then
		dbg_mobf.mob_state_lvl2("MOBF: " .. entity.data.name 
			.. " switching to state model ")
		newentity = spawning.replace_entity(entity,
							mob_state.get_entity_name(entity.data,state),true)
	else
		dbg_mobf.mob_state_lvl2("MOBF: " .. entity.data.name 
			.. " switching to default model ")
		newentity = spawning.replace_entity(entity,entity.data.modname 
							.. ":"..entity.data.name .. "__default",true)
	end	
	
	if newentity ~= nil then
		dbg_mobf.mob_state_lvl2("MOBF: " .. entity.data.name 
			.. " replaced entity=" .. tostring(entity) .. " by newentity=" 
			.. tostring(newentity))
		return newentity
	else
		return entity
	end	
end

-------------------------------------------------------------------------------
-- name: switch_switch_movgenentity(entity,state)
--
--! @brief helper function to swich a movement based on new state
--! @ingroup mob_state
--
--! @param entity to change movement gen
--! @param state to take new entity
-------------------------------------------------------------------------------
function mob_state.switch_movgen(entity,state)
	local mov_to_set = nil
	
	--determine new movement gen
	if state.movgen ~= nil then
		mov_to_set = getMovementGen(state.movgen)
	else
		local default_state = mob_state.get_state_by_name(entity,"default")
		mov_to_set = getMovementGen(default_state.movgen)
	end
	
	--check if new mov gen differs from old one
	if mov_to_set ~= nil and
		mov_to_set ~= entity.dynamic_data.current_movement_gen then
		entity.dynamic_data.current_movement_gen = mov_to_set
		
		--TODO initialize new movement gen
		entity.dynamic_data.current_movement_gen.init_dynamic_data(entity,mobf_get_current_time())
	end
end


-------------------------------------------------------------------------------
-- name: change_state(entity,state)
--
--! @brief change state for an entity
--! @ingroup mob_state
--
--! @param entity to change state
--! @param state to change to
--!
--! @return the new entity or nil
-------------------------------------------------------------------------------
function mob_state.change_state(entity,state)

	dbg_mobf.mob_state_lvl2("MOBF: " .. entity.data.name 
		.. " state change called entity=" .. tostring(entity) .. " state:" 
		.. dump(state))
	--check if time precondition handler tells us to stop state change
	--if not mob_state.precon_time(state) then
	--	return
	--end
	
	--check if custom precondition handler tells us to stop state change
	if state ~= nil and
		type(state.custom_preconhandler) == "function" then
		if not state.custom_preconhandler(entity,state) then
			dbg_mobf.mob_state_lvl1("MOBF: " .. entity.data.name 
				.. " custom precondition handler didn't meet ")
			return nil
		end
	end
	
	--switch to default state if no state given
	if state == nil then
		dbg_mobf.mob_state_lvl2("MOBF: " .. entity.data.name 
			.. " invalid state switch, switching to default instead of: " 
			.. dump(state))
		state = mob_state.get_state_by_name("default")
	end
	
	local entityname = entity.data.name
	local statename = state.name
	
	dbg_mobf.mob_state_lvl2("MOBF: " .. entityname .. " switching state to " 
		.. statename)
	
	if entity.dynamic_data.state == nil then
		mobf_bug_warning(LOGLEVEL_WARNING,"MOBF BUG!!! mob_state no state dynamic data")
		return nil
	end

	if entity.dynamic_data.state.current ~= state.name then
		dbg_mobf.mob_state_lvl2("MOBF: " .. entity.data.name 
			.. " different states now really changeing to " .. state.name)
		local switchedentity = mob_state.switch_entity(entity,state)
		mob_state.switch_movgen(switchedentity,state)
		
		switchedentity.dynamic_data.state.time_to_next_change = mob_state.getTimeToNextState(state.typical_state_time)
		switchedentity.dynamic_data.state.current = state.name
		
		graphics.set_animation(switchedentity,state.animation)
		dbg_mobf.mob_state_lvl2("MOBF:  time to next change = " 
			.. switchedentity.dynamic_data.state.time_to_next_change)
		
		if switchedentity ~= entity then
			return switchedentity
		end
	else
		dbg_mobf.mob_state_lvl2("MOBF: " .. entity.data.name 
			.. " switching to same state as before")
		entity.dynamic_data.state.time_to_next_change = mob_state.getTimeToNextState(state.typical_state_time)
		dbg_mobf.mob_state_lvl2("MOBF:  time to next change = " 
			.. entity.dynamic_data.state.time_to_next_change)
	end
	
	return nil
end


-------------------------------------------------------------------------------
-- name: getTimeToNextState(typical_state_time)
--
--! @brief helper function to calculate a gauss distributed random value
--! @ingroup mob_state
--
--! @param typical_state_time center of gauss
--!
--! @return a random value around typical_state_time
-------------------------------------------------------------------------------
function mob_state.getTimeToNextState(typical_state_time)

	if typical_state_time == nil then
		mobf_bug_warning(LOGLEVEL_WARNING,"MOBF MOB BUG!!! missing typical state time!")
		typical_state_time = mob_state.default_state_time
	end

	local u1 = 2 * math.random() -1
	local u2 = 2 * math.random() -1
	
	local q = u1*u1 + u2*u2
	
	local maxtries = 0
	
	while (q == 0 or q >= 1) and maxtries < 10 do
		u1 = math.random()
		u2 = math.random() * -1
		q = u1*u1 + u2*u2
		
		maxtries = maxtries +1
	end
	
	--abort random generation
	if maxtries >= 10 then
		return typical_state_time
	end

	local p = math.sqrt( (-2*math.log(q))/q )
	
	local retval = 2
	--calculate normalized state time with maximum error or half typical time up and down
	if math.random() < 0.5 then
		retval = typical_state_time + ( u1*p * (typical_state_time/2))
	else
		retval = typical_state_time + ( u2*p * (typical_state_time/2))
	end
	
	--! ensure minimum state time of 2 seconds
	if retval > 2 then
		return retval
	else
		return 2
	end
end

-------------------------------------------------------------------------------
-- name: prepare_states(mob)
--
--! @brief register a mob within mob framework
--! @ingroup mob_state
--
--! @param mob a mob declaration
-------------------------------------------------------------------------------
function mob_state.prepare_states(mob)
	local custom_combat_state_defined = false
	local default_state_defined = false

	--add graphics for any mob state
	if mob.states ~= nil then
		for s = 1, #mob.states , 1 do
			graphic_to_set = graphics.prepare_info(mob.states[s].graphics,
										mob.states[s].graphics_3d,
										mob.modname,"_"..mob.name, mob.states[s].name)
	
			if graphic_to_set ~= nil then
				mobf.register_entity(":" .. mob_state.get_entity_name(mob,mob.states[s]), graphic_to_set, mob)
			end
			
			if mob.states[s].name == "combat" then
				custom_combat_state_defined = true
			end
			
			if mob.states[s].name == "default" then
				default_state_defined = true
			end
			

		end
	else
		mob.states = {}
	end
	
	--add a default combat state if no custom state is defined
	if mob.combat ~= nil then
		if custom_combat_state_defined == false then
				table.insert(mob.states,
						{
						name = "combat",
						custom_preconhandler = nil,
						movgen = "follow_mov_gen",
						typical_state_time = -1,
						chance = 0,
						})
		end
	end
	
	
	--legacy code to run old mobs
	if not default_state_defined then
		minetest.log(LOGLEVEL_WARNING,"MOBF: -----------------------------------------------------------------------------------------")
		minetest.log(LOGLEVEL_WARNING,"MOBF: Automatic default state generation is legacy code subject to be removed in later version.")
		minetest.log(LOGLEVEL_WARNING,"MOBF: -----------------------------------------------------------------------------------------")
	
		local default_state = {
			name 				= "default",
			movgen 				= mob.movement.default_gen,
			graphics 			= mob.graphics,
			graphics_3d 		= mob.graphics_3d,
			chance				= 0,
			typical_state_time 	= 30,
			animation           = "walk",
		}
		
		graphic_to_set = graphics.prepare_info(default_state.graphics,
										default_state.graphics_3d,
										mob.modname,"_"..mob.name)
	
		if graphic_to_set ~= nil then
			mobf.register_entity(":" .. mob_state.get_entity_name(mob,default_state),
									graphic_to_set, mob)
		end
		
		--replace old mobs by new default state mobs
		minetest.register_entity(":".. mob.modname .. ":"..mob.name,
			 {
			 	new_name = mob_state.get_entity_name(mob,default_state),
			 	on_activate = function(self,staticdata)
			 		minetest.log(LOGLEVEL_INFO, "MOBF replacing " .. self.name 
			 			.. " by " .. self.new_name)
			 		local pos = self.object:getpos()
			 		self.object:remove()
			 		
			 		minetest.env:add_entity(pos,self.new_name)
			 	end
			 })
		
		table.insert(mob.states,default_state)
	end
end

--!@}