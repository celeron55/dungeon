local version = "0.0.17"

minetest.log("action","MOD: loading animal_vombie ... ")

local vombie_groups = {
						not_in_creative_inventory=1
					}

local selectionbox_vombie = {-0.3, -1.2, -0.5, 0.3, 1, 0.5}

local modpath = minetest.get_modpath("animal_vombie")

dofile (modpath .. "/flame.lua")

function vombie_drop()
	local result = {}
	if math.random() < 0.05 then
		table.insert(result,"animalmaterials:bone 2")
	else
		table.insert(result,"animalmaterials:bone 1")
	end
	
	table.insert(result,"animalmaterials:meat_undead 1")
	
	return result
end

function vombie_on_step_handler(entity,now,dtime)
	local pos = entity.getbasepos(entity)
	local current_light = minetest.env:get_node_light(pos)
	
	--print("vombie on step: current_light:" .. current_light .. " max light: " .. LIGHT_MAX .. " 3dmode:" .. dump(minetest.setting_getbool("disable_animals_3d_mode")))

	if current_light ~= nil and
		current_light > LIGHT_MAX and
		minetest.setting_getbool("mobf_disable_3d_mode") ~= true and
		minetest.setting_getbool("vombie_3d_burn_animation_enabled") == true then
		
		
		local xdelta = (math.random()-0.5)
		local zdelta = (math.random()-0.5)
		--print("receiving sun damage: " .. xdelta .. " " .. zdelta)
		local newobject=minetest.env:add_entity( {	x=pos.x + xdelta,
													y=pos.y,
													z=pos.z + zdelta },
										"animal_vombie:vombie_flame")

		--add particles
	end
end

function vombie_on_activate_handler(entity)

        local pos = entity.object:getpos()
        
        local current_light = minetest.env:get_node_light(pos)
            
        if current_light == nil then
            minetest.log(LOGLEVEL_ERROR,"ANIMALS: Bug!!! didn't get a light value for ".. printpos(pos))
            return
        end
        --check if animal is in sunlight
        if ( current_light > LIGHT_MAX) then
            --don't spawn vombie in sunlight
            spawning.remove(entity)
        end
end

vombie_prototype = {
		name="vombie",
		modname="animal_vombie",
	
		generic = {
					description="Vombie",
					base_health=8,
					kill_result=vombie_drop,
					armor_groups= {
						fleshy=3,
						daemon=1,
					},
					groups = vombie_groups,
					envid="on_ground_1",
					custom_on_step_handler = vombie_on_step_handler,
					custom_on_activate_handler = vombie_on_activate_handler,
				},
		movement =  {
					min_accel=0.3,
					max_accel=1.5,
					max_speed=2,
					pattern="stop_and_go",
					canfly=false,
					follow_speedup=10,
					},
		combat = {
					angryness=1,
					starts_attack=true,
					sun_sensitive=true,
					melee = {
						maxdamage=2,
						range=2, 
						speed=1,
						},
					distance 		= nil,
					self_destruct 	= nil,
					},
		
		spawning = {
					rate=0.05,
					density=30,
					algorithm="at_night_spawner",
					height=2,
					respawndelay=60,
					},
		sound = {
					random = {
								name="animal_vombie_random_1",
								min_delta = 10,
								chance = 0.5,
								gain = 0.05,
								max_hear_distance = 5,
								},
					sun_damage = {
								name="animal_vombie_sun_damage",
								gain = 0.25,
								max_hear_distance = 7,
								},
					},
		animation = {
				stand = {
					start_frame = 0,
					end_frame   = 80,
					},
				walk = {
					start_frame = 168,
					end_frame   = 188,
					},
				attack = {
					start_frame = 81,
					end_frame   = 110,
					},
			},
		states = {
				{
					name = "default",
					movgen = "none",
					typical_state_time = 30,
					chance = 0,
					animation = "stand",
					graphics = {
						sprite_scale={x=4,y=4},
						sprite_div = {x=6,y=2},
						visible_height = 2.2,
						visible_width = 1,
					},
					graphics_3d = {
						visual = "mesh",
						mesh = "animal_vombie_vombie.b3d",
						textures = {"animal_vombie_vombie_mesh.png"},
						collisionbox = selectionbox_vombie,
						visual_size= {x=1,y=1,z=1},
						},
				},
				{
					name = "walking",
					movgen = "probab_mov_gen",
					typical_state_time = 120,
					chance = 0.5,
					animation = "walk",
				},
				{ 
					name = "combat",
					typical_state_time = 9999,
					chance = 0.0,
					animation = "attack",
					movgen="follow_mov_gen",
				},
			}
		}


--register with animals mod
minetest.log("action","\tadding mob "..vombie_prototype.name)
mobf_add_mob(vombie_prototype)
minetest.log("action","MOD: animal_vombie mod          version " .. version .. " loaded")