-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file init.lua
--! @brief animalmaterials
--! @copyright Sapier
--! @author Sapier
--! @date 2013-01-27
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------
minetest.log("action","MOD: animalmaterials loading ...")
local version = "0.0.15"


animalmaterialsdata = {}
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Node definitions
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Item definitions
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- deamondeath sword
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
minetest.register_tool("animalmaterials:sword_deamondeath", {
	description = "Sword (Deamondeath)",
	inventory_image = "default_tool_steelsword.png",
	tool_capabilities = {
		full_punch_interval = 0.50,
		max_drop_level=1,
		groupcaps={
			fleshy={times={[1]=2.00, [2]=0.80, [3]=0.40}, uses=10, maxlevel=1},
			snappy={times={[2]=0.70, [3]=0.30}, uses=40, maxlevel=1},
			choppy={times={[3]=0.70}, uses=40, maxlevel=0},
			deamon={times={[1]=0.25, [2]=0.10, [3]=0.05}, uses=20, maxlevel=3},
		}
	}
	})
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- scissors
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
minetest.register_tool("animalmaterials:scissors", {
	description = "Scissors",
	inventory_image = "animalmaterials_scissors.png",
	tool_capabilities = {
		max_drop_level=0,
		groupcaps={
			wool  = {uses=20,maxlevel=1}
		}
	},
})
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- lasso
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
minetest.register_craftitem("animalmaterials:lasso", {
	description = "Lasso",
	image = "animalmaterials_lasso.png",
	stack_max=10,
})
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- net
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
minetest.register_craftitem("animalmaterials:net", {
	description = "Net",
	image = "animalmaterials_net.png",
	stack_max=10,
})
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- saddle
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
minetest.register_craftitem("animalmaterials:saddle", {
	description = "Saddle",
	image = "animalmaterials_saddle.png",
	stack_max=1
})
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- meat
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
minetest.register_craftitem("animalmaterials:meat_raw", {
	description = "Raw meat",
	image = "animalmaterials_meat_raw.png",
	on_use = minetest.item_eat(1),
	groups = { meat=1, eatable=1 },
	stack_max=25
})
minetest.register_craftitem("animalmaterials:meat_pork", {
	description = "Pork (raw)",
	image = "animalmaterials_meat_raw.png",
	on_use = minetest.item_eat(1),
	groups = { meat=1, eatable=1 },
	stack_max=25
})
minetest.register_craftitem("animalmaterials:meat_beef", {
	description = "Beef (raw)",
	image = "animalmaterials_meat_raw.png",
	on_use = minetest.item_eat(1),
	groups = { meat=1, eatable=1 },
	stack_max=25
})
minetest.register_craftitem("animalmaterials:meat_chicken", {
	description = "Chicken (raw)",
	image = "animalmaterials_meat_raw.png",
	on_use = minetest.item_eat(1),
	groups = { meat=1, eatable=1 },
	stack_max=25
})
minetest.register_craftitem("animalmaterials:meat_lamb", {
	description = "Lamb (raw)",
	image = "animalmaterials_meat_raw.png",
	on_use = minetest.item_eat(1),
	groups = { meat=1, eatable=1 },
	stack_max=25
})
minetest.register_craftitem("animalmaterials:meat_venison", {
	description = "Venison (raw)",
	image = "animalmaterials_meat_raw.png",
	on_use = minetest.item_eat(1),
	groups = { meat=1, eatable=1 },
	stack_max=25
})
minetest.register_craftitem("animalmaterials:meat_undead", {
	description = "Meat (not quite dead)",
	image = "animalmaterials_meat_raw.png",
	on_use = minetest.item_eat(-2),
	groups = { meat=1, eatable=1 },
	stack_max=5
})
minetest.register_craftitem("animalmaterials:meat_toxic", {
	description = "Toxic Meat",
	image = "animalmaterials_meat_raw.png",
	on_use = minetest.item_eat(-5),
	groups = { meat=1, eatable=1 },
	stack_max=5
})
minetest.register_craftitem("animalmaterials:meat_ostrich", {
	description = "Ostrich Meat",
	image = "animalmaterials_meat_raw.png",
	on_use = minetest.item_eat(-5),
	groups = { meat=1, eatable=1 },
	stack_max=5
})

minetest.register_craftitem("animalmaterials:fish_bluewhite", {
	description = "Fish (bluewhite)",
	image = "animalmaterials_meat_raw.png",
	on_use = minetest.item_eat(1),
	groups = { meat=1, eatable=1 },
	stack_max=25
})

minetest.register_craftitem("animalmaterials:fish_clownfish", {
	description = "Fish (clownfish)",
	image = "animalmaterials_meat_raw.png",
	on_use = minetest.item_eat(1),
	groups = { meat=1, eatable=1 },
	stack_max=25
})
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- feather
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
minetest.register_craftitem("animalmaterials:feather", {
	description = "Feather",
	image = "animalmaterials_feather.png",
	stack_max=25
})
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- milk
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
minetest.register_craftitem("animalmaterials:milk", {
	description = "Milk",
	image = "animalmaterials_milk.png",
	on_use = minetest.item_eat(1),
	groups = { eatable=1 },
	stack_max=10
})
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- egg
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
minetest.register_craftitem("animalmaterials:egg", {
	description = "Egg",
	image = "animalmaterials_egg.png",
	stack_max=10
})

minetest.register_craftitem("animalmaterials:egg_big", {
	description = "Egg (big)",
	image = "animalmaterials_egg_big.png",
	stack_max=5
})

animalmaterialsdata["animalmaterials_egg"] = {
			graphics_3d = {
				visual = "mesh",
				mesh   = "animalmaterials_egg_ent.b3d",
				textures = { "animalmaterials_egg_ent_mesh.png" },
				collisionbox = { -0.12,-0.125,-0.12,0.12,0.125,0.12 },
				visual_size     = {x=1,y=1,z=1},
				}
	}
	
animalmaterialsdata["animalmaterials_egg_big"] = {
			graphics_3d = {
				visual = "mesh",
				mesh   = "animalmaterials_egg_ent.b3d",
				textures = { "animalmaterials_egg_ent_mesh.png" },
				collisionbox = { -0.24,-0.25,-0.24,0.24,0.25,0.24 },
				visual_size     = {x=2,y=2,z=2},
				}
	}

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- bone
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
minetest.register_craftitem("animalmaterials:bone", {
	description = "Bone",
	image = "animalmaterials_bone.png",
	stack_max=25
})
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- furs
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
minetest.register_craftitem("animalmaterials:fur", {
	description = "Fur",
	image = "animalmaterials_fur.png",
	stack_max=25
})

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- scale
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
minetest.register_craftitem("animalmaterials:scale_golden", {
	description = "Scale (golden)",
	image = "animalmaterials_scale_golden.png",
	stack_max=25
})
minetest.register_craftitem("animalmaterials:scale_white", {
	description = "Scale (white)",
	image = "animalmaterials_scale_white.png",
	stack_max=25
})
minetest.register_craftitem("animalmaterials:scale_grey", {
	description = "Scale (grey)",
	image = "animalmaterials_scale_grey.png",
	stack_max=25
})
minetest.register_craftitem("animalmaterials:scale_blue", {
	description = "Scale (blue)",
	image = "animalmaterials_scale_blue.png",
	stack_max=25
})

minetest.log("action","MOD: animalmaterials mod version " .. version .. " loaded")
