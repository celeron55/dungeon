-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file mobf.lua
--! @brief class containing mob initialization functions
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--
--
--! @defgroup mobf Basic mob entity functions
--! @brief a component containing basic functions for mob handling and initialization
--! @ingroup framework_int
--! @{ 
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

mobf = {}

mobf.on_step_callbacks = {}
mobf.on_punch_callbacks = {}
mobf.on_rightclick_callbacks = {}


------------------------------------------------------------------------------
-- name: register_on_step_callback(callback)
--
--! @brief make a new on_step callback known to mobf
--! @ingroup mobf
--
--! @param callback to make known to mobf
-------------------------------------------------------------------------------
function mobf.register_on_step_callback(callback)

	if callback.configcheck == nil or
		type(callback.configcheck) ~= "function" then
		return false
	end
	
	if callback.handler == nil or
		type(callback.configcheck) ~= "function" then
		return false
	end

	table.insert(mobf.on_step_callbacks,callback)
end


------------------------------------------------------------------------------
-- name: init_on_step_callbacks(entity,now)
--
--! @brief initalize callbacks to be used on step
--! @ingroup mobf
--
--! @param entity entity to initialize on_step handler
--! @param now current time
-------------------------------------------------------------------------------
function mobf.init_on_step_callbacks(entity,now)
	entity.on_step_hooks = {}
	
	if #mobf.on_step_callbacks > 32 then
		mobf_bug_warning(LOGLEVEL_ERROR,"MOBF BUG!!!: " .. #mobf.on_step_callbacks 
			.. " incredible high number of onstep callbacks registred!")
	end

	dbg_mobf.mobf_core_lvl2("MOBF: initializing " .. #mobf.on_step_callbacks 
		..  " on_step callbacks for " .. entity.data.name 
		.. " entity=" .. tostring(entity))
	for i = 1, #mobf.on_step_callbacks , 1 do
		if mobf.on_step_callbacks[i].configcheck(entity) then
			dbg_mobf.mobf_core_lvl2("MOBF:	(" .. i .. ") enabling callback " 
				.. mobf.on_step_callbacks[i].name)
			table.insert(entity.on_step_hooks,mobf.on_step_callbacks[i].handler)
			if type(mobf.on_step_callbacks[i].init) == "function" then
				dbg_mobf.mobf_core_lvl2("MOBF:	(" .. i .. ") executing init function for " 
					.. mobf.on_step_callbacks[i].name)
				mobf.on_step_callbacks[i].init(entity,now)
			else
				dbg_mobf.mobf_core_lvl2("MOBF:	(" .. i .. ") no init function defined")
			end
		else
			dbg_mobf.mobf_core_lvl2("MOBF:	(" .. i .. ") callback " 
				.. mobf.on_step_callbacks[i].name .. " disabled due to config check")
		end
	end

end

------------------------------------------------------------------------------
-- name: register_on_rightclick_callback(callback)
--
--! @brief make a new on_rightclick callback known to mobf
--! @ingroup mobf
--
--! @param callback to make known to mobf
-------------------------------------------------------------------------------
function mobf.register_on_rightclick_callback(callback)

	if callback.configcheck == nil or
		type(callback.configcheck) ~= "function" then
		return false
	end
	
	if callback.handler == nil or
		type(callback.configcheck) ~= "function" then
		return false
	end

	table.insert(mobf.on_rightclick_callbacks,callback)
end


------------------------------------------------------------------------------
-- name: register_on_punch_callback(callback)
--
--! @brief make a new on_punch callback known to mobf
--! @ingroup mobf
--
--! @param callback the callback to register in mobf
-------------------------------------------------------------------------------
function mobf.register_on_punch_callback(callback)
	if callback.configcheck == nil or
		type(callback.configcheck) ~= "function" then
		return false
	end
	
	if callback.handler == nil or
		type(callback.configcheck) ~= "function" then
		return false
	end

	table.insert(mobf.on_punch_callbacks,callback)
end


------------------------------------------------------------------------------
-- name: init_on_punch_callbacks(entity,now)
--
--! @brief initalize callbacks to be used on punch
--! @ingroup mobf
--
--! @param entity entity to initialize on_punch handler
--! @param now current time
-------------------------------------------------------------------------------
function mobf.init_on_punch_callbacks(entity,now)
	entity.on_punch_hooks = {}

	dbg_mobf.mobf_core_lvl2("MOBF: initializing " .. #mobf.on_punch_callbacks 
		..  " on_punch callbacks for " .. entity.data.name 
		.. " entity=" .. tostring(entity))
	for i = 1, #mobf.on_punch_callbacks , 1 do
		if mobf.on_punch_callbacks[i].configcheck(entity) and
			type(mobf.on_punch_callbacks[i].handler) == "function" then
			dbg_mobf.mobf_core_lvl2("MOBF:	(" .. i .. ") enabling callback " 
				.. mobf.on_punch_callbacks[i].name)
			table.insert(entity.on_punch_hooks,mobf.on_punch_callbacks[i].handler)
			
			if type(mobf.on_punch_callbacks[i].init) == "function" then
				dbg_mobf.mobf_core_lvl2("MOBF:	(" .. i .. ") executing init function for " 
					.. mobf.on_punch_callbacks[i].name)
				mobf.on_punch_callbacks[i].init(entity,now)
			else
				dbg_mobf.mobf_core_lvl2("MOBF:	(" .. i .. ") no init function defined")
			end
		else
			dbg_mobf.mobf_core_lvl2("MOBF:	(" .. i .. ") callback " 
				.. mobf.on_punch_callbacks[i].name .. " disabled due to config check")
		end
	end
end

------------------------------------------------------------------------------
-- name: init_on_rightclick_callbacks(entity,now)
--
--! @brief initalize callbacks to be used on punch
--! @ingroup mobf
--
--! @param entity entity to initialize on_punch handler
--! @param now current time
-------------------------------------------------------------------------------
function mobf.init_on_rightclick_callbacks(entity,now)
	entity.on_rightclick_hooks = {}

	dbg_mobf.mobf_core_lvl2("MOBF: initializing " .. #mobf.on_rightclick_callbacks 
		..  " on_rightclick callbacks for " .. entity.data.name .. " entity=" .. tostring(entity))
	for i = 1, #mobf.on_rightclick_callbacks , 1 do
		if mobf.on_rightclick_callbacks[i].configcheck(entity) and
			type(mobf.on_rightclick_callbacks[i].handler) == "function" then
			dbg_mobf.mobf_core_lvl2("MOBF:	(" .. i .. ") enabling callback " 
				.. mobf.on_rightclick_callbacks[i].name)
			table.insert(entity.on_rightclick_hooks,mobf.on_rightclick_callbacks[i].handler)
			
			if type(mobf.on_rightclick_callbacks[i].init) == "function" then
				dbg_mobf.mobf_core_lvl2("MOBF:	(" .. i .. ") executing init function for " 
					.. mobf.on_rightclick_callbacks[i].name)
				mobf.on_rightclick_callbacks[i].init(entity,now)
			else
				dbg_mobf.mobf_core_lvl2("MOBF:	(" .. i .. ") no init function defined")
			end
		else
			dbg_mobf.mobf_core_lvl2("MOBF:	(" .. i .. ") callback " 
				.. mobf.on_rightclick_callbacks[i].name .. " disabled due to config check")
		end
	end
end

------------------------------------------------------------------------------
-- name: get_basepos(entity)
--
--! @brief get basepos for an entity
--! @ingroup mobf
--
--! @param entity entity to fetch basepos
--! @return basepos of mob
-------------------------------------------------------------------------------
function mobf.get_basepos(entity)
	local pos = entity.object:getpos()
	local nodeatpos = minetest.env:get_node(pos)
	
	dbg_mobf.mobf_core_helper_lvl3("MOBF: " .. entity.data.name 
		.. " Center Position: " .. printpos(pos) .. " is: " .. nodeatpos.name)

	-- if visual height is more than one block the center of base block is 
	-- below the entities center
	if (entity.collisionbox[2] < -0.5) then
		pos.y = pos.y + (entity.collisionbox[2] + 0.5)
		dbg_mobf.mobf_core_helper_lvl3("MOBF: collision box lower end: " 
			.. entity.collisionbox[2])
	end

	nodeatpos = minetest.env:get_node(pos)
	dbg_mobf.mobf_core_helper_lvl3("MOBF: Base Position: " .. printpos(pos) 
		.. " is: " .. nodeatpos.name)

	return pos
end

------------------------------------------------------------------------------
-- name: mobf_activate_handler(self,staticdata)
--
--! @brief hanlder called for basic mob initialization
--! @ingroup mobf
--
--! @param self entity to initialize onstep handler
--! @param staticdata data to use for initialization
-------------------------------------------------------------------------------
function mobf.activate_handler(self,staticdata)
	
	
	--do some initial checks
	local pos = self.object:getpos()
	
	if pos == nil then
		minetest.log(LOGLEVEL_ERROR,"MOBF: mob at nil pos!")
	end
	local current_node = minetest.env:get_node(pos)
	
	
	if current_node == nil then
		minetest.log(LOGLEVEL_ERROR,"MOBF: trying to activate mob in nil node! removing")
		
		spawning.remove_uninitialized(self,staticdata)
		return
	end
	

	if environment.is_media_element(current_node.name,self.environment.media) == false then
		minetest.log(LOGLEVEL_WARNING,"MOBF: trying to activate mob " 
			.. self.data.name .. " at invalid position")
		minetest.log(LOGLEVEL_WARNING,"	Activation at: " 
			.. current_node.name .. " --> removing")
		spawning.remove_uninitialized(self,staticdata)
		return
	end
	
	
	
	--do initialization of dynamic modules
	local now = mobf_get_current_time()
	
	spawning.init_dynamic_data(self,now)
	
	mobf.init_on_step_callbacks(self,now)
	mobf.init_on_punch_callbacks(self,now)
	mobf.init_on_rightclick_callbacks(self,now)
	
	--initialize ride support
	mobf_ride.init(self)
	
	--check if this was a replacement mob
	if self.dyndata_delayed ~= nil then
		minetest.log(LOGLEVEL_ERROR,"MOBF: delayed activation for replacement mob." 
			.."This shouldn't happen at all but if we can fix it")
		self.dynamic_data = dyndata_delayed.data
		self.object:set_hp(dyndata_delayed.health)
		self.object:setyaw(dyndata_delayed.entity_orientation)
		dyndata_delayed = nil
		return
	end
	
	--restore saved data
	local retval = mobf_deserialize_permanent_entity_data(staticdata)
	
	if self.dynamic_data.spawning ~= nil then
		if mobf_pos_is_zero(retval.spawnpoint) ~= true then
			self.dynamic_data.spawning.spawnpoint = retval.spawnpoint
		else
			self.dynamic_data.spawning.spawnpoint = mobf_round_pos(pos)
		end
		self.dynamic_data.spawning.player_spawned = retval.playerspawned
		
		if retval.original_spawntime ~= -1 then
			self.dynamic_data.spawning.original_spawntime = retval.original_spawntime
		end
		
		if retval.spawner ~= nil then
			minetest.log(LOGLEVEL_INFO,"MOBF: setting spawner to: " 
				.. retval.spawner)
			self.dynamic_data.spawning.spawner = retval.spawner
		end
		
		--only relevant if mob has different states
		if retval.state ~= nil and
			self.dynamic_data.state ~= nil then
			minetest.log(LOGLEVEL_INFO,"MOBF: setting current state to: " 
				.. retval.state)
			self.dynamic_data.state.current = retval.state
			

		end
	end
	
	
	local current_state = mob_state.get_state_by_name(self,self.dynamic_data.state.current)
	local default_state = mob_state.get_state_by_name(self,"default")
	
	if self.dynamic_data.state.current == nil then
		current_state = default_state
	end
	
	
	--initialize move gen
	if current_state.movgen ~= nil then
		dbg_mobf.mobf_core_lvl1("MOBF: setting movegen to: " .. current_state.movgen)
		self.dynamic_data.current_movement_gen = getMovementGen(current_state.movgen)
	else
		dbg_mobf.mobf_core_lvl1("MOBF: setting movegen to: " .. default_state.movgen)
		self.dynamic_data.current_movement_gen = getMovementGen(default_state.movgen)
	end
	
	if current_state.animation ~= nil then
		dbg_mobf.mobf_core_lvl1("MOBF: setting animation to: " .. current_state.animation)
		graphics.set_animation(self,current_state.animation)
	else
		dbg_mobf.mobf_core_lvl1("MOBF: setting animation to: " .. dump(default_state.animation))
		graphics.set_animation(self,default_state.animation)
	end
		
	mobf_assert_backtrace(self.dynamic_data.current_movement_gen ~= nil)

	self.dynamic_data.current_movement_gen.init_dynamic_data(self,now)
	
	--initialize armor groups
	if self.data.generic.armor_groups ~= nil then
		self.object:set_armor_groups(self.data.generic.armor_groups)
	end

	--initialize height level
	pos = environment.fix_base_pos(self, self.collisionbox[2] * -1)

	--custom on activate handler
	if (self.data.generic.custom_on_activate_handler ~= nil) then
		self.data.generic.custom_on_activate_handler(self)
	end
	
	self.dynamic_data.initialized = true
end





------------------------------------------------------------------------------
-- name: register_entity(entityname,graphics)
--
--! @brief register an entity
--! @ingroup mobf
--
--! @param name of entity to add
--! @param graphics graphics to use for entity
--! @param mob data to use
-------------------------------------------------------------------------------
function mobf.register_entity(name, graphics, mob)
	dbg_mobf.mobf_core_lvl1("MOBF: registering new entity: " .. name)
	minetest.register_entity(name,
			 {
				physical        = true,
				collisionbox    = graphics.collisionbox,
				visual          = graphics.visual,
				textures        = graphics.textures,
				visual_size     = graphics.visual_size,
				spritediv       = graphics.spritediv,
				mesh            = graphics.mesh,
				mode            = graphics.mode,
				initial_sprite_basepos 	= {x=0, y=0},
				makes_footstep_sound = true,
				automatic_rotate = true,
				groups          = mob.generic.groups,
				hp_max          = mob.generic.base_health,
				



		--	actions to be done by mob on its own
			on_step = function(self, dtime)
			
				local starttime = mobf_get_time_ms()
				
				if self.removed ~= false then
					mobf_bug_warning(LOGLEVEL_ERROR,"MOBF: on_step: " 
						.. self.data.name .. " on_step for removed entity????")
					return
				end
				
				if self.dynamic_data == nil then
					mobf_bug_warning(LOGLEVEL_ERROR,"MOBF: on_step: " 
						.. "no dynamic data available!")
					return
				end
			
				if (self.dynamic_data.initialized == false) then
					if entity_at_loaded_pos(self.object:getpos()) then
						mobf.activate_handler(self,self.dynamic_data.last_static_data)
						self.dynamic_data.last_static_data = nil
					else
						return
					end
				end
				
				--do special ride callback
				if mobf_ride.on_step_callback(self) then
					return
				end
			
				self.current_dtime = self.current_dtime + dtime
				
				local now = mobf_get_current_time()
						
				if self.current_dtime < 0.25 then
					return
				end
				
				--check lifetime
				if spawning.lifecycle(self,now) == false then
				    return
				end
				
				mobf_warn_long_fct(starttime,"on_step lifecycle","lifecycle")
				
				--movement generator
				self.dynamic_data.current_movement_gen.callback(self,now)
				
				mobf_warn_long_fct(starttime,"on_step movement","movement")
				
				if #self.on_step_hooks > 32 then
					mobf_bug_warning(LOGLEVEL_ERROR,"MOBF BUG!!!: " 
						.. tostring(self) .. " incredible high number of onstep hooks! "
						.. #self.on_step_hooks .. " ohlist: " .. tostring(self.on_step_hooks))
				end
				
				--dynamic modules
				for i = 1, #self.on_step_hooks, 1 do
					--check return value if on_step hook tells us to stop any other processing
					if self.on_step_hooks[i](self,now,self.current_dtime) == false then
						dbg_mobf.mobf_core_lvl1("MOBF: on_step: " .. self.data.name 
							.. " aborting callback processing entity=" .. tostring(self))
						break
					end
					mobf_warn_long_fct(starttime,"callback nr " .. i,"callback_os_" 
						.. self.data.name .. "_" .. i)
				end
				
				mobf_warn_long_fct(starttime,"on_step_total","on_step_total")
				self.current_dtime = 0
				end,

		--player <-> mob interaction
			on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir)
				local starttime = mobf_get_time_ms()
				local now = mobf_get_current_time()
				
				for i = 1, #self.on_punch_hooks, 1 do
					if self.on_punch_hooks[i](self,hitter,now,
							time_from_last_punch, tool_capabilities, dir) then
						return
					end
					mobf_warn_long_fct(starttime,"callback nr " .. i,"callback_op_" 
						.. self.data.name .. "_" .. i)
				end
				end,

		--rightclick is only used for debug reasons by now
			on_rightclick = function(self, clicker)
				local starttime = mobf_get_time_ms()
				for i = 1, #self.on_rightclick_hooks, 1 do
					if self.on_rightclick_hooks[i](self,clicker) then
						break
					end
					mobf_warn_long_fct(starttime,"callback nr " .. i,"callback_or_" 
						.. self.data.name .. "_" .. i)
				end
				
				--tesrcode only
				--mobf_ride.attache_player(self,clicker)
				end,

		--do basic mob initialization on activation
			on_activate = function(self,staticdata)
				
				self.dynamic_data = {}
				self.dynamic_data.initialized = false
				
				--make sure entity is in loaded area at initialization
				local pos = self.object:getpos()
				
				if pos ~= nil and
					entity_at_loaded_pos(pos) then
						mobf.activate_handler(self,staticdata)
					else
						minetest.log(LOGLEVEL_INFO,"MOBF: animal activated at invalid position .. delaying activation")
						self.dynamic_data.last_static_data = staticdata
					end
				end,
			
			getbasepos       = mobf.get_basepos,
			is_on_ground     = function(entity)
			
				local basepos = entity.getbasepos(entity)
				local posbelow = { x=basepos.x, y=basepos.y-1,z=basepos.z}
	
				for dx=-1,1 do
				for dz=-1,1 do
					local fp0 = posbelow
					local fp = { x= posbelow.x + (0.5*dx),
								  y= posbelow.y,
								  z= posbelow.z + (0.5*dz) }
					local n = minetest.env:get_node(fp)
					if not mobf_is_walkable(n) then
						return true
					end
				end
				end
				
				return false
				end,
				
		--prepare permanent data
			get_staticdata = function(self)
				return mobf_serialize_permanent_entity_data(self)
				end,

		--custom variables for each mob
			data                    = mob,
			environment             = environment_list[mob.generic.envid],
			current_dtime           = 0,
			}
		)
end

-------------------------------------------------------------------------------
-- name: register_mob_item(mob)
--
--! @brief add mob item for catchable mobs
--! @ingroup mobf
--
--! @param name name of mob
--! @param modname name of mod mob is defined in
--! @param description description to use for mob
-------------------------------------------------------------------------------
function mobf.register_mob_item(name,modname,description)
	minetest.register_craftitem(modname..":"..name, {
		description = description,
		image = modname.."_"..name.."_item.png",
		on_place = function(item, placer, pointed_thing)
			if pointed_thing.type == "node" then
				local pos = pointed_thing.above
				
				local entity = spawning.spawn_and_check(modname..":"..name,"__default",pos,"item_spawner")

				if entity ~= nil then
					entity.dynamic_data.spawning.player_spawned = true
						
					if placer:is_player(placer) then
						minetest.log(LOGLEVEL_INFO,"MOBF: mob placed by " .. placer:get_player_name(placer))
						entity.dynamic_data.spawning.spawner = placer:get_player_name(placer)
					end
						
					if entity.data.generic.custom_on_place_handler ~= nil then
						entity.data.generic.custom_on_place_handler(entity, placer, pointed_thing)
					end

					item:take_item()
				end
				return item
				end
			end
		})
end

-------------------------------------------------------------------------------
-- name: blacklist_handling(mob)
--
--! @brief add mob item for catchable mobs
--! @ingroup mobf
--
--! @param mob
-------------------------------------------------------------------------------
function mobf.blacklisthandling(mob)
	local blacklisted = minetest.registered_entities[mob.modname.. ":"..mob.name]
	
	
	local on_activate_fct = nil
	
	--remove unknown animal objects
	if minetest.setting_getbool("mobf_delete_disabled_mobs") then
		on_activate_fct = function(self,staticdata)
				self.object:remove()
			end
		
		
		
		--cleanup spawners too
		if minetest.registered_entities[mob.modname.. ":"..mob.name] == nil and
			environment_list[mob.generic.envid] ~= nil and
			mobf_spawn_algorithms[mob.spawning.algorithm] ~= nil and
			type(mobf_spawn_algorithms[mob.spawning.algorithm].register_cleanup) == "function" then
			
			mobf_spawn_algorithms[mob.spawning.algorithm].register_cleanup(mob.modname.. ":" .. mob.name)
			
			if mob.spawning.algorithm_secondary ~= nil and
				type(mobf_spawn_algorithms.register_spawn[mob.spawning.algorithm_secondary].register_cleanup) == "function" then
					mobf_spawn_algorithms.register_spawn[mob.spawning.algorithm_secondary].register_cleanup(mob.modname.. ":" .. mob.name)
			end
		end
	else
		on_activate_fct = function(self,staticdata)
				self.object:setacceleration({x=0,y=0,z=0})
				self.object:setvelocity({x=0,y=0,z=0})
			end
	end
	
	if minetest.registered_entities[mob.modname.. ":"..mob.name] == nil then
	
		--cleanup mob entities
		minetest.register_entity(mob.modname.. ":"..mob.name .. "__default",
			{
				on_activate = on_activate_fct
			})
		
		if mob.states ~= nil then
			for s = 1, #mob.states , 1 do
				minetest.register_entity(":".. mob_state.get_entity_name(mob,mob.states[s]),
				{
					on_activate = on_activate_fct
				})
			end
		end
	end

	
	if blacklisted == nil then
		minetest.log(LOGLEVEL_INFO,"MOBF: " .. mob.modname.. ":"..mob.name .. " was blacklisted")
	else
		minetest.log(LOGLEVEL_ERROR,"MOBF: " .. mob.modname.. ":"..mob.name .. " already known not registering mob with same name!")
	end
end