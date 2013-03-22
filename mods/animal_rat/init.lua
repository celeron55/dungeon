-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file init.lua
--! @brief rat implementation
--! @copyright Sapier
--! @author Sapier
--! @date 2013-01-27
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------
minetest.log("action","MOD: animal_rat loading ...")

local version = "0.0.8"

local selectionbox_rat = {-0.2, -0.0625, -0.2, 0.2, 0.125, 0.2}

local rat_groups = {
						not_in_creative_inventory=1
					}

rat_prototype = {
		name="rat", 
		modname="animal_rat",
	
		generic = {
					description="Rat (Animals)",
					base_health=2,
					kill_result="",
					armor_groups= {
						fleshy=3,
					},
					groups = rat_groups,
					envid="on_ground_1",
				},
		movement =  {
					default_gen="probab_mov_gen",
					min_accel=0.4,
					max_accel=0.6,
					max_speed=2,
					pattern="run_and_jump_low",
					canfly=false,
					},
		catching = {
					tool="animalmaterials:net",
					consumed=true,
					},
		spawning = {
					rate=0.02,
					density=250,
					algorithm="forrest_mapgen",
					height=1
					},
		animation = {
				walk = {
					start_frame = 1,
					end_frame   = 40,
					},
				stand = {
					start_frame = 41,
					end_frame   = 80,
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
					mesh = "animal_rat.b3d",
					textures = {"animal_rat_mesh.png"},
					collisionbox = selectionbox_rat,
					visual_size= {x=1,y=1,z=1},
					},
				graphics = {
					sprite_scale={x=1,y=1},
					sprite_div = {x=6,y=1},
					visible_height = 1,
					visible_width = 1,
					},	
				typical_state_time = 10,
				},
				{ 
				name = "walking",
				movgen = "probab_mov_gen",
				chance = 0.75,
				animation = "walk",
				typical_state_time = 180,
				},
			},
		}



--register mod
minetest.log("action","\tadding "..rat_prototype.name)
mobf_add_mob(rat_prototype)
minetest.log("action","MOD: animal_rat mod             version " .. version .. " loaded")