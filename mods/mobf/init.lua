-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file init.lua
--! @brief main module file responsible for including all parts of mob framework mod
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--
--! @defgroup framework_int Internal framework subcomponent API
--! @brief this functions are used to provide additional features to mob framework
--! e.g. add additional spawn algorithms, movement generators, environments ...
--
--
--! @defgroup framework_mob Mob Framework API 
--! @brief this functions are used to add a mob to mob framework
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

print("MOD: mobf loading ...")

--! @brief runtime data required to be setup once on start
mobf_rtd = {
	--!is mob running with fire support
	fire_enabled			= false,
	--!do we have luatrace
	luatrace_enabled		= false,
	--!do we have inventory plus support
	inventory_plus_enabled = false,
	--!registry for movement patterns
	movement_patterns		= {},
	--!registry of mobs
	registred_mob			= {},
	--!registred mobs_data
	registred_mob_data		= {},
}

--!path of mod
mobf_modpath = minetest.get_modpath("mobf")

LOGLEVEL_INFO     = "verbose"
LOGLEVEL_NOTICE   = "info"
LOGLEVEL_WARNING  = "action"
LOGLEVEL_ERROR    = "error"
LOGLEVEL_CRITICAL = "error"

--include debug trace functions
dofile (mobf_modpath .. "/debug_trace.lua")

--include engine
dofile (mobf_modpath .. "/generic_functions.lua")
dofile (mobf_modpath .. "/environment.lua")
dofile (mobf_modpath .. "/movement_generic.lua")
dofile (mobf_modpath .. "/graphics.lua")
dofile (mobf_modpath .. "/movement_gen_registry.lua")
dofile (mobf_modpath .. "/harvesting.lua")
dofile (mobf_modpath .. "/weapons.lua")
dofile (mobf_modpath .. "/fighting.lua")
dofile (mobf_modpath .. "/random_drop.lua")
dofile (mobf_modpath .. "/sound.lua")
dofile (mobf_modpath .. "/permanent_data.lua")
dofile (mobf_modpath .. "/ride.lua")
dofile (mobf_modpath .. "/mobf.lua")
dofile (mobf_modpath .. "/api.lua")
dofile (mobf_modpath .. "/debug.lua")
dofile (mobf_modpath .. "/mob_state.lua")
dofile (mobf_modpath .. "/inventory.lua")

--include spawning support
dofile (mobf_modpath .. "/spawning.lua")

--include movement generators
dofile (mobf_modpath .. "/mgen_probab/main_probab.lua")
dofile (mobf_modpath .. "/mgen_follow/main_follow.lua")
dofile (mobf_modpath .. "/mgen_rasterized/mgen_raster.lua")
dofile (mobf_modpath .. "/mgen_jordan4ibanez/mgen_jordan4ibanez.lua")
dofile (mobf_modpath .. "/mov_gen_none.lua")

mobf_version = "2.0.5"

--! @brief define tools used for more than one mob
function mobf_init_basic_tools()	
	minetest.register_craft({
		output = "animalmaterials:lasso 5",
		recipe = {
			{'', "wool:white",''},
			{"wool:white",'', "wool:white"},
			{'',"wool:white",''},
		}
	})
	
	minetest.register_craft({
		output = "animalmaterials:net 1",
		recipe = {
			{"wool:white",'',"wool:white"},
			{'', "wool:white",''},
			{"wool:white",'',"wool:white"},
		}
	})
	
	minetest.register_craft({
	output = 'animalmaterials:sword_deamondeath',
	recipe = {
		{'animalmaterials:bone'},
		{'animalmaterials:bone'},
		{'default:stick'},
	}
	})

end


--! @brief main initialization function
function mobf_init_framework()
	minetest.log(LOGLEVEL_NOTICE,"MOBF: Initializing mob framework")
	mobf_init_basic_tools()
	
	minetest.log(LOGLEVEL_NOTICE,"MOBF: Reading mob blacklist")
	local mobf_mob_blacklist_string = minetest.setting_get("mobf_blacklist")
	
	if mobf_mob_blacklist_string ~= nil then
		mobf_rtd.registred_mob = minetest.deserialize(mobf_mob_blacklist_string)
		
		if mobf_rtd.registred_mob == nil then
			minetest.log(LOGLEVEL_ERROR,"MOBF: Error on serializing blacklist!")
			mobf_rtd.registred_mob = {}
		end
	end
	
	minetest.log(LOGLEVEL_NOTICE,"MOBF: Initialize external mod dependencys...")
	mobf_init_mod_deps()
	
	minetest.log(LOGLEVEL_NOTICE,"MOBF: Initializing probabilistic movement generator")
	movement_gen.initialize()
	
	minetest.log(LOGLEVEL_NOTICE,"MOBF: Initializing weaponry..")
	mobf_init_weapons()

	minetest.log(LOGLEVEL_NOTICE,"MOBF: Initializing debug hooks..")
	mobf_debug.init()
	
	minetest.log(LOGLEVEL_NOTICE,"MOBF: Initialize mobf supplied modules..")
	mobf_init_modules()
	
	-- initialize luatrace if necessary
	if mobf_rtd.luatrace_enabled then
		luatrace = require("luatrace")
	end
	
	-- register privilege to change mobf settings
	minetest.register_privilege("mobfw_admin", 
	{
		description = "Player may change mobf settings",
		give_to_singleplayer = true
	})

	print("MOD: mob framework mod "..mobf_version.." loaded")
end

--! @brief initialize mod dependencys
function mobf_init_mod_deps()
	local modlist = minetest.get_modnames()
	
	for i=1,#modlist,1 do
		if modlist[i] == "fire" then
			mobf_rtd.fire_enabled = true
		end
		
		if modlist[i] == "inventory_plus" then
			mobf_rtd.inventory_plus_enabled = true
		end
	end	
end

--! @brief initialize mobf submodules
function mobf_init_modules()

	--state change callback
	mobf.register_on_step_callback({
			name = "state_change",
			handler = mob_state.callback,
			init = mob_state.initialize,
			configcheck = function(entity)
				if entity.data.states ~= nil then
					return true
				end
				return false
			end
			})

	--auto transform hook
	mobf.register_on_step_callback({
			name = "transform",
			handler = transform,
			init = nil,
			configcheck = function(entity)
					if entity.data.auto_transform ~= nil then
						return true
					end
					return false
				end
				})
	
	--combat hook
	mobf.register_on_step_callback({
			name = "combat",
			handler = fighting.combat,
			init = fighting.init_dynamic_data,
			configcheck = function(entity)
					if entity.data.combat ~= nil then
						return true
					end
					return false
				end
				})
				
	--attack hook
	mobf.register_on_step_callback({
			name = "aggression",
			handler = fighting.aggression,
			init = nil, -- already done by fighting.combat
			configcheck = function(entity)
					if entity.data.combat ~= nil then
						return true
					end
					return false
				end
				})
		


	--workaround for shortcomings in spawn algorithm
	mobf.register_on_step_callback({
			name = "check_pop_dense",
			handler = spawning.check_population_density,
			init = spawning.init_dynamic_data,
			configcheck = function(entity)
					return true
				end
				})

	--random drop hook
	mobf.register_on_step_callback({
			name = "random_drop",
			handler = random_drop.callback,
			init = random_drop.init_dynamic_data,
			configcheck = function(entity)
					if entity.data.random_drop ~= nil then
						return true
					end
					return false
				end
				})

	--random sound hook
	mobf.register_on_step_callback({
			name = "sound",
			handler = sound.play_random,
			init = sound.init_dynamic_data,
			configcheck = function(entity)
						if entity.data.sound ~= nil and
							entity.data.sound.random ~= nil then
						return true
					end
					return false
				end
				})

	--visual change hook
	mobf.register_on_step_callback({
			name = "update_orientation",
			handler = graphics.update_orientation,
			init = nil,
			configcheck = function(entity)
					return true
				end
				})


	--custom hook
	mobf.register_on_step_callback({
			name = "custom_hooks",
			handler = function(entity,now,dtime)
					if type(entity.data.generic.custom_on_step_handler) == "function" then
						entity.data.generic.custom_on_step_handler(entity,now,dtime)
					end
				end,
			configcheck = function(entity)
					return true
				end
				})
				

	--on punch callbacks
	mobf.register_on_punch_callback({
			name = "harvesting",
			handler = harvesting.callback,
			init = harvesting.init_dynamic_data,
			configcheck = function(entity)
					if (entity.data.catching ~= nil and
							entity.data.catching.tool ~= "" ) or
							entity.data.harvest ~= nil then
							return true
					end
					return false
				end
				})
				
	mobf.register_on_punch_callback({
			name		= "riding",
			handler		= mobf_ride.on_punch_callback,
			configcheck	= mobf_ride.is_enabled
			})
	
	mobf.register_on_punch_callback({
			name = "punching",
			handler = fighting.hit,
			configcheck = function(entity)
					return true
				end
				})
				
				
	--on rightclick callbacks
	--Note debug needs to be registred FIRST!
	mobf.register_on_rightclick_callback({
			name = "debugcallback",
			handler		= mobf_debug.rightclick_callback,
			configcheck	= function(entity)
					return true
				end
			})
			
	mobf.register_on_rightclick_callback({
			name = "tradercallback",
			handler		= mob_inventory.trader_callback,
			configcheck	= mob_inventory.config_check
			})
			

end

mobf_init_framework()

dofile (mobf_modpath .. "/compatibility.lua")
