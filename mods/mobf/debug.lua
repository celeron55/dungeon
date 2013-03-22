-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file debug.lua
--! @brief contains debug functions for mob framework
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--!
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

--! @defgroup debug_in_game In game debugging functions
--! @brief debugging functions to be called from in game
--! @ingroup framework_int
--! @{

mobf_debug = {}

-------------------------------------------------------------------------------
-- name: print_usage(player,command,toadd)
--
--! @brief send errormessage to player
--
--! @param player name of player to print usage
--! @param command display usage for this command
--! @param toadd additional information to transfer to player
-------------------------------------------------------------------------------
function mobf_debug.print_usage(player, command, toadd)

	if toadd == nil then
		toadd = ""
	end

	if command == "spawnmob" then
		print("CMD: ".. player .."> ".. "Usage: /spawnmob <mobname> <X,Y,Z> " .. toadd)
		minetest.chat_send_player(player, "Usage: /spawnmob <mobname> <X,Y,Z> " .. toadd)
	end

	if command == "ukn_mob" then
		print("CMD: ".. player .."> "..  "Unknown mob name "..toadd)
		minetest.chat_send_player(player, "Unknown mob name "..toadd)
	end

	if command == "inv_pos" then
		print("CMD: ".. player .."> "..  "Invalid position "..toadd)
		minetest.chat_send_player(player, "Invalid position "..toadd)
	end

	if command == "mob_spawned" then
		print("CMD: ".. player .."> "..  "Mob successfully spawned "..toadd)
		minetest.chat_send_player(player, "Mob successfully spawned "..toadd)
	end
end

-------------------------------------------------------------------------------
-- name: spawn_mob(name,param)
--
--! @brief handle a spawn mob command
--
--! @param name name of player
--! @param param parameters received
------------------------------------------------------------------------------
function mobf_debug.spawn_mob(name,param)
	print("name: " .. name .. " param: " .. dump(param))
	
	local parameters = param:split(" ")
	
	if #parameters ~= 2 then
		mobf_debug.print_usage(name,"spawnmob")
		return
	end
	
	local pos_strings = parameters[2]:split(",")
	
	if #pos_strings ~= 3 then
		mobf_debug.print_usage(name,"spawmob")
		return
	end

	if mobf_is_known_mob(parameters[1]) ~= true then
		mobf_debug.print_usage(name,"ukn_mob", ">"..parameters[1].."<") 
		return true
	end

	local spawnpoint = {
						x=tonumber(pos_strings[1]),
						y=tonumber(pos_strings[2]),
						z=tonumber(pos_strings[3])
						}

	if spawnpoint.x == nil or
		spawnpoint.y == nil or
		spawnpoint.z == nil then
		mobf_debug.print_usage(name,"spawnmob")	
		return
	end

	spawning.spawn_and_check(parameters[1],"__default",spawnpoint,"mobf_debug_spawner")
end

-------------------------------------------------------------------------------
-- name: list_active_mobs(name,param)
--
--! @brief print list of all current active mobs
--
--! @param name name of player
--! @param param parameters received
------------------------------------------------------------------------------
function mobf_debug.list_active_mobs(name,param)
	
	local count = 1
	for index,value in pairs(minetest.luaentities) do 
		if value.data ~= nil and value.data.name ~= nil then
			local tosend = count .. ": " .. value.data.name .. " at " 
				.. printpos(value.object:getpos())
			print(tosend)
			minetest.chat_send_player(name,tosend)
			count = count +1
		end
	end
end

-------------------------------------------------------------------------------
-- name: add_tools(name,param)
--
--! @brief add toolset for testing
--
--! @param name name of player
--! @param param parameters received
------------------------------------------------------------------------------
function mobf_debug.add_tools(name,param)
	local player = minetest.env:get_player_by_name(name)
	
	if player ~= nil then
		player:get_inventory():add_item("main", "animalmaterials:lasso 20")
		player:get_inventory():add_item("main", "animalmaterials:net 20")
		player:get_inventory():add_item("main", "animalmaterials:scissors 1")
		player:get_inventory():add_item("main", "animalmaterials:glass 10")	
	end

end

-------------------------------------------------------------------------------
-- name: list_defined_mobs(name,param)
--
--! @brief list all registred mobs
--
--! @param name name of player
--! @param param parameters received
------------------------------------------------------------------------------
function mobf_debug.list_defined_mobs(name,param)

	local text = ""
	for i,val in ipairs(mobf_rtd.registred_mob) do
		text = text .. val .. " "
	end
	minetest.chat_send_player(name, "MOBF: "..text)
end

-------------------------------------------------------------------------------
-- name: init()
--
--! @brief initialize debug commands chat handler
--
------------------------------------------------------------------------------
function mobf_debug.init()

	minetest.register_chatcommand("spawnmob",
		{
			params		= "<name> <pos>",
			description = "spawn a mob at position" ,
			privs		= {mobfw_admin=true},
			func		= mobf_debug.spawn_mob
		})
		
	minetest.register_chatcommand("listactivemobs",
		{
			params		= "",
			description = "list all currently active mobs" ,
			privs		= {mobfw_admin=true},
			func		= mobf_debug.list_active_mobs
		})
		
	minetest.register_chatcommand("listdefinedmobs",
		{
			params		= "",
			description = "list all currently defined mobs" ,
			privs		= {mobfw_admin=true},
			func		= mobf_debug.list_defined_mobs
		})
		
	minetest.register_chatcommand("mob_add_tools",
		{
			params		= "",
			description = "add some mob specific tools to player" ,
			privs		= {mobfw_admin=true},
			func		= mobf_debug.add_tools
		})
		
	minetest.register_chatcommand("mobf_version",
		{
			params		= "",
			description = "show mobf version number" ,
			privs		= {},
			func		= function(name,param)
								minetest.chat_send_player(name,"MOBF version: " .. mobf_version)
							end 
		})

	if mobf_rtd.luatrace_enabled then
		minetest.register_chatcommand("traceon",
			{
				params		= "",
				description = "start luatrace tracing" ,
				privs		= {mobfw_admin=true},
				func		= luatrace.tron()
			})
			
		minetest.register_chatcommand("traceon",
			{
				params		= "",
				description = "stop luatrace tracing" ,
				privs		= {mobfw_admin=true},
				func		= luatrace.troff()
			})
	end
end


-------------------------------------------------------------------------------
-- name: handle_spawnhouse(name,message)
--
--! @brief spawn small house
--
--! @param entity entity rightclicked
--! @param player player doing rightclick
------------------------------------------------------------------------------
function mobf_debug.rightclick_callback(entity,player)
	local lifetime = mobf_get_current_time() - entity.dynamic_data.spawning.original_spawntime
	print("MOBF: " .. entity.data.name .. " is alive for " .. lifetime .. " seconds")
	print("MOBF: \tCurrent state:               " .. entity.dynamic_data.state.current )
	print("MOBF: \tCurrent movgen:              " .. entity.dynamic_data.current_movement_gen.name )
	if entity.dynamic_data.current_movement_gen.name == "follow_mov_gen" then
			local basepos  = entity.getbasepos(entity)
			local targetpos = entity.dynamic_data.spawning.spawnpoint	
			if entity.dynamic_data.movement.guardspawnpoint ~= true then
				targetpos = entity.dynamic_data.movement.target:getpos()
			end
			print("MOBF: \t\tmovement state:              " .. mgen_follow.identify_movement_state(basepos,targetpos) )
	end
	print("MOBF: \tTime to state change:        " .. entity.dynamic_data.state.time_to_next_change .. " seconds")
	print("MOBF: \tCurrent environmental state: " .. environment.pos_is_ok(entity.getbasepos(entity),entity))
	print("MOBF: \tCurrent accel:               " .. printpos(entity.object:getacceleration()))
	print("MOBF: \tCurrent speed:               " .. printpos(entity.object:getvelocity()))
	return false
end


--!@}
