-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file init.lua
--! @brief dungeonmaster implementation
--! @copyright Sapier
--! @author Sapier
--! @date 2013-01-27
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------
minetest.log("action","MOD: animal_dm loading ...")
local version = "0.0.15"

local dm_groups = {
                        not_in_creative_inventory=1
                    }

local selectionbox_dm = {-0.75, -1, -0.75, 0.75, 1, 0.75}

dm_prototype = {   
		name="dm",
		modname="animal_dm",
	
		generic = {
					description="Dungeonmaster (MOBF)",
					base_health=10,
					kill_result="",
					armor_groups= {
						fleshy=1,
						deamon=1,
					},
					groups = dm_groups,
					envid="simple_air"
				},				
		movement =  {
					min_accel=0.2,
					max_accel=0.4,
					max_speed=0.25,
					pattern="stop_and_go",
					canfly=false,
					follow_speedup=5,
					},
		combat = {
					angryness=0.99,
					starts_attack=true,
					sun_sensitive=true,
					melee = {
						maxdamage=3,
						range=5, 
						speed=1,
						},
					distance = {
						attack="mobf:fireball_entity",
						range =15,
						speed = 1,
						},				
					self_destruct = nil,
					},
		
		spawning = {		
					rate=0.02,
					density=750,
					algorithm="shadows_spawner",
					height=3,
					respawndelay = 60,
					},
		sound = {
					random = {
								name="animal_dm_random_1",
								min_delta = 30,
								chance = 0.5,
								gain = 0.5,
								max_hear_distance = 5,
								},
					distance = {
								name="animal_dm_fireball",
								gain = 0.5,
								max_hear_distance = 7,
								},
					die = {
								name="animal_dm_die",
								gain = 0.7,
								max_hear_distance = 7,
								},
					melee = {
								name="animal_dm_hit",
								gain = 0.7,
								max_hear_distance = 5,
								},
					},
		animation = {
				walk = {
					start_frame = 31,
					end_frame   = 60,
					},
				stand = {
					start_frame = 1,
					end_frame   = 30,
					},
				combat = {
					start_frame = 61,
					end_frame   = 90,
					},
			},
		states = {
				{ 
				name = "default",
				movgen = "none",
				chance = 0,
				animation = "stand",
				graphics_3d = {
					visual = "mesh",
					mesh = "animal_dm.b3d",
					textures = {"animal_dm_mesh.png"},
					collisionbox = selectionbox_dm,
					visual_size= {x=1,y=1,z=1},
					},
				graphics = {
					sprite_scale={x=4,y=4},
					sprite_div = {x=6,y=1},
					visible_height = 2,
					},
				typical_state_time = 30,
				},
				{ 
				name = "walking",
				movgen = "probab_mov_gen",
				chance = 0.25,
				animation = "walk",
				typical_state_time = 180,
				},
				{
				movgen="follow_mov_gen",
				name = "combat",
				chance = 0,
				animation = "combat",
				typical_state_time = 0,
				},
			},
		}
		
dm_debug = function (msg)
    --minetest.log("action", "mobs: "..msg)
    --minetest.chat_send_all("mobs: "..msg)
end

local modpath = minetest.get_modpath("animal_dm")
dofile (modpath .. "/vault.lua")

--register with animals mod
minetest.log("action", "adding mob "..dm_prototype.name)
if mobf_add_mob(dm_prototype) then
	dofile (modpath .. "/vault.lua")
end
minetest.log("action","MOD: animal_dm mod              version " .. version .. " loaded")