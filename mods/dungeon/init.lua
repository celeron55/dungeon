-- minetest/dungeon: dungeon

local DUNGEON_Y = -1000

-- Define this so ores don't get placed on walls
minetest.register_node("dungeon:stone", {
	description = "Dungeon Stone",
	tiles = {"default_stone.png"},
	groups = {},
	legacy_mineral = true,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_alias("mapgen_singlenode", "dungeon:stone")

-- Make chests not pickable up
local def = minetest.registered_nodes["default:chest"]
def.groups = {}
minetest.register_node(":default:chest", def)

local v3 = {}
function v3.new(x, y, z)
	if x == nil then
		return {
			x = 0,
			y = 0,
			z = 0
		}
	end
	if type(x) == "table" then
		return {
			x = x.x,
			y = x.y,
			z = x.z,
		}
	end
	return {
		x = x,
		y = y,
		z = z,
	}
end
function v3.floor(v)
	return {
		x = math.floor(v.x),
		y = math.floor(v.y),
		z = math.floor(v.z),
	}
end
function v3.cmp(v, w)
	return (
		v.x == w.x and
		v.y == w.y and
		v.z == w.z
	)
end
function v3.add(v, w)
	return {
		x = v.x + w.x,
		y = v.y + w.y,
		z = v.z + w.z,
	}
end
function v3.sub(v, w)
	return {
		x = v.x - w.x,
		y = v.y - w.y,
		z = v.z - w.z,
	}
end
function v3.mul(v, a)
	return {
		x = v.x * a,
		y = v.y * a,
		z = v.z * a,
	}
end
function v3.len(v)
	return math.sqrt(
		math.pow(v.x, 2) +
		math.pow(v.y, 2) +
		math.pow(v.z, 2)
	)
end
function v3.norm(v)
	return v3.mul(v, 1.0 / v3.len(v))
end
function v3.distance(v, w)
	return math.sqrt(
		math.pow(v.x - w.x, 2) +
		math.pow(v.y - w.y, 2) +
		math.pow(v.z - w.z, 2)
	)
end

mobs = {}

mobs.make_vault_part = function(p, part, pr)
	local ns = nil
	local top_y = 2
	local mob_y = 0
	local mob = nil
	local item = nil
	if part == 'w' then
		ns = {
			{name='default:cobble'},
			{name='default:cobble'},
			{name='default:cobble'},
			{name='default:cobble'},
		}
	elseif part == 'W' then
		top_y = 3
		ns = {
			{name='default:cobble'},
			{name='default:cobble'},
			{name='default:cobble'},
			{name='default:cobble'},
			{name='default:cobble'},
			{name='default:cobble'},
		}
	elseif part == 'c' then
		ns = {
			{name='default:cobble'},
			{name='air'},
			{name='air'},
			{name='default:cobble'},
		}
	elseif part == 'f' then
		ns = {
			{name='air'},
			{name='air'},
			{name='air'},
			{name='default:cobble'},
		}
	elseif part == 'l' then
		top_y = 3
		ns = {
			{name='default:cobble'},
			{name='air'},
			{name='air'},
			{name='air'},
			{name='air'},
			{name='default:lava_source'},
		}
	elseif part == 'm' then
		ns = {
			{name='default:cobble'},
			{name='air'},
			{name='air'},
			{name='default:cobble'},
		}
		local a = pr:next(1,2)
		if a == 1 then
			mob = "animal_dm:dm__default"
		else
			mob = "animal_vombie:vombie__default"
		end
	elseif part == 'r' then
		ns = {
			{name='default:cobble'},
			{name='air'},
			{name='air'},
			{name='default:cobble'},
		}
		mob = "animal_rat:rat__default"
	elseif part == 'C' then
		top_y = 3
		ns = {
			{name='default:cobble'},
			{name='air'},
			{name='air'},
			{name='air'},
			{name='default:cobble'},
		}
	elseif part == 'd' then
		ns = {
			{name='default:cobble'},
			{name='air'},
			{name='air'},
			{name='default:cobble'},
		}
	elseif part == 'a' then
		ns = {
			nil,
			{name='air'},
			{name='air'},
			nil,
		}
	elseif part == 'A' then
		ns = {
			nil,
			{name='air'},
			{name='air'},
			{name='air'},
			{name='default:cobble'},
		}
	elseif part == 'i' then
		ns = {
			{name='default:cobble'},
			{name='air'},
			{name='air'},
			{name='default:cobble'},
		}
		if pr:next(1,4) == 1 then
			item = 'default:torch '..tostring(pr:next(1,15))
		elseif pr:next(1,4) == 1 then
			item = 'default:apple '..tostring(pr:next(1,3))
		elseif pr:next(1,6) == 1 then
			item = 'default:sword_stone '..tostring(pr:next(2,5)*100)
		end
	elseif part == 't' then
		local invcontent = {}
		if pr:next(1,4) == 1 then
			table.insert(invcontent, 'default:apple '..tostring(pr:next(1,5)))
		end
		if pr:next(1,3) == 1 then
			table.insert(invcontent, 'default:cobble '..tostring(pr:next(1,5)))
		end
		if pr:next(1,3) == 1 then
			table.insert(invcontent, 'default:torch '..tostring(pr:next(1,20)))
		end
		if pr:next(1,3) == 1 then
			table.insert(invcontent, 'default:sword_stone '..tostring(pr:next(400,655)*100))
		end
		if pr:next(1,10) == 1 then
			table.insert(invcontent, 'default:sword_steel '..tostring(pr:next(0,655)*100))
		end
		if pr:next(1,6) == 1 then
			table.insert(invcontent, 'bucket:bucket_empty 1')
		end
		if pr:next(1,8) == 1 then
			table.insert(invcontent, 'bucket:bucket_lava 1')
		end
		if pr:next(1,20) == 1 then
			table.insert(invcontent, 'bucket:bucket_water 1')
		end
		if pr:next(1,34) == 1 then
			table.insert(invcontent, 'default:nyancat 1')
			table.insert(invcontent, 'default:nyancat_rainbow '..tostring(pr:next(1,6)))
		end
		if pr:next(1,2) == 1 then
			table.insert(invcontent, 'default:gravel '..tostring(pr:next(1,10)))
		end
		if pr:next(1,30) == 1 then
			table.insert(invcontent, 'default:bookshelf '..tostring(pr:next(1,2)))
		end
		if pr:next(1,8) == 1 then
			table.insert(invcontent, 'default:cactus '..tostring(pr:next(1,2)))
		end
		if pr:next(1,40) == 1 then
			table.insert(invcontent, 'default:rail '..tostring(pr:next(1,10)))
		end
		if pr:next(1,5) == 1 then
			table.insert(invcontent, 'default:ladder '..tostring(pr:next(1,9)))
		end
		if pr:next(1,30) == 1 then
			table.insert(invcontent, 'default:sign_wall 1')
		end
		if pr:next(1,60) == 1 then
			table.insert(invcontent, 'default:steelblock '..tostring(pr:next(1,6)))
		end
		ns = {
			{name='default:cobble'},
			{name='air'},
			{name='default:chest', inv=invcontent},
			{name='default:cobble'},
		}
	else
		return
	end

	for i=1,#ns do
		local dy = top_y + 1 - i
		local p2 = v3.new(p)
		p2.y = p2.y + dy
		local oldn = minetest.env:get_node(p2)
		local n = ns[i]
		if n and oldn.name ~= "air" then
			if n.name == 'default:cobble' then
				local perlin = minetest.env:get_perlin(123, 2, 0.8, 2.0)
				if perlin:get3d(p2) >= 0.0 then
					n.name = 'default:mossycobble'
				end
			end
			minetest.env:set_node(p2, ns[i])
			if n.inv then
				local meta = minetest.env:get_meta(p2)
				local inv = meta:get_inventory()
				for _,itemstring in ipairs(n.inv) do
					inv:add_item('main', itemstring)
				end
			end
		end
	end
	if mob then
		minetest.env:add_entity(v3.add(p, v3.new(0, mob_y, 0)), mob)
	end
	if item then
		minetest.env:add_item(v3.add(p, v3.new(0, mob_y, 0)), item)
	end
end

mobs.generate_vault = function(vault_def, p, dir, seed)
	local dim_z = #vault_def
	assert(dim_z > 0)
	local dim_x = #vault_def[1]
	if not v3.cmp(dir, v3.new(0,0,1)) then return end
	--print("Making vault at "..minetest.pos_to_string(p))
	--if dim_x >= 14 then
	--	mobs.debug("Making large vault at "..minetest.pos_to_string(p))
	--else
	--	mobs.debug("Making vault at "..minetest.pos_to_string(p))
	--end
	-- Find door in definition
	local def_door_p = nil
	for dx=1,dim_x do
	for dz=1,dim_z do
		if vault_def[dim_z+1-dz][dx] == 'd' then
			def_door_p = v3.new(dx,0,dz)
		end
		if def_door_p then break end
	end
		if def_door_p then break end
	end
	--print("Vault door found at "..minetest.pos_to_string(def_door_p).." in definition")
	assert(def_door_p)
	local pr = PseudoRandom(seed)
	local randseed = seed
	for dx=1,dim_x do
	for dz=1,dim_z do
		local p2 = v3.add(v3.sub(p, def_door_p), v3.new(dx, 0, dz))
		local part = vault_def[dim_z+1-dz][dx]
		--print("Making vault part "..dump(part).." at "..minetest.pos_to_string(p2))
		mobs.make_vault_part(p2, part, pr)
		randseed = randseed + 1
	end
	end
end

-- Definition is for Z=up, X=right, dir={x=0,y=0,z=1}
mobs.vault_defs = {
	{
		{'w','w','w','w','w','w','w','w','w','w'},
		{'w','c','c','c','c','c','C','C','c','w'},
		{'w','c','C','c','c','c','C','C','m','w'},
		{'w','C','C','C','w','w','C','C','c','w'},
		{'w','C','C','C','w','w','C','C','c','w'},
		{'w','r','C','c','w','w','C','w','w','w'},
		{'w','c','c','c','w','w','C','w',nil,nil},
		{'w','w','w','w','w','w','C','w',nil,nil},
		{nil,nil,nil,nil,nil,'w','d','w',nil,nil},
		{nil,nil,nil,nil,nil,nil,'A',nil,nil,nil},
	},
	{
		{'w','w','w','w','w','w','w','w'},
		{'w','c','c','c','c','C','c','w'},
		{'w','C','c','c','C','C','c','w'},
		{'w','C','c','c','C','C','c','w'},
		{'w','C','t','w','C','C','r','w'},
		{'w','C','c','w','C','w','d','w'},
		{'w','w','w','w','C','w','A',nil},
		{'w','w','w','w','C','w',nil,nil},
		{nil,nil,nil,'w','w','w',nil,nil},
	},
	{
		{'W','W','W','W','W','W','W','W','W','W','W','W','W','W','W','W'},
		{'W','l','l','l','l','l','l','c','i','l','l','l','l','l','l','W'},
		{'W','l','l','l','l','l','l','f','f','l','l','l','l','l','l','W'},
		{'W','l','l','l','l','l','l','f','f','l','l','l','l','l','l','W'},
		{'W','c','l','l','l','l','l','f','f','l','l','l','l','l','m','W'},
		{'W','c','l','l','l','l','l','f','f','l','l','l','l','l','c','W'},
		{'W','c','l','l','t','f','f','f','f','l','l','l','l','l','c','W'},
		{'W','c','l','l','l','l','l','f','f','l','l','l','l','l','c','W'},
		{'W','m','l','l','l','l','l','f','f','l','l','l','l','l','c','W'},
		{'W','l','l','l','l','l','l','f','f','l','l','l','l','l','l','W'},
		{'W','l','l','l','l','l','l','f','f','l','l','l','l','l','l','W'},
		{'W','l','l','l','l','l','l','f','f','l','l','l','l','l','l','W'},
		{'W','W','W','W','W','W','W','W','d','W','W','W','W','W','W','W'},
		{nil,nil,nil,nil,nil,nil,nil,nil,'A',nil,nil,nil,nil,nil,nil,nil},
	},
	{
		{'w','w','w','w','w','w','w','w'},
		{'w','c','c','c','m','C','c','w'},
		{'w','C','c','c','C','C','c','w'},
		{'w','C','C','C','C','C','C','w'},
		{'w','C','C','C','C','C','C','w'},
		{'w','C','C','C','C','C','C','w'},
		{'w','C','C','C','C','C','C','w'},
		{'w','C','c','c','C','C','r','w'},
		{'w','C','c','w','C','w','d','w'},
		{'w','c','w','w','C','w','A',nil},
		{'w','c','C','C','C','w',nil,nil},
		{nil,nil,nil,'w','w','w',nil,nil},
	},
	{
		{'w','w','w','w','w','w','w','w'},
		{'w','c','c','c','c','C','i','w'},
		{'w','C','c','c','C','C','c','w'},
		{'w','C','w','w','C','C','c','w'},
		{'w','C','c','c','C','C','c','w'},
		{'w','C','C','w','C','w','d','w'},
		{'w','c','C','C','C','w','A',nil},
		{'w','c','C','C','C','w',nil,nil},
		{'w','C','C','C','C','C','C','w'},
		{'w','C','C','C','C','C','C','w'},
		{nil,nil,nil,'w','w','w',nil,nil},
	},
	{
		{'w','w','w','w','w','w','w','w'},
		{'w','c','c','c','c','C','c','w'},
		{'w','C','c','c','w','C','c','w'},
		{'w','C','w','w','w','w','c','w'},
		{'w','C','C','C','C','C','c','w'},
		{'w','C','c','w','C','w','d','w'},
		{'w','i','w','w','C','w','A',nil},
		{'w','c','C','C','C','w',nil,nil},
		{nil,nil,nil,'w','w','w',nil,nil},
	},
	{
		{'w','w','w','w','w','w','w','w'},
		{'w','i','c','c','c','C','t','w'},
		{'w','C','w','c','C','C','c','w'},
		{'w','c','w','w','w','C','w','w'},
		{'w','C','w','c','C','C','C','w'},
		{'w','C','w','c','C','C','d','w'},
		{'w','c','w','w','w','C','A',nil},
		{'w','c','C','C','C','C',nil,nil},
		{nil,nil,nil,'w','w','w',nil,nil},
	},
	{
		{'W','W','W','W','W','W','W','W','W','W','W','W','W','W','W','W'},
		{'W','C','C','C','C','C','C','C','C','C','C','C','C','C','C','W'},
		{'W','C','C','C','C','C','C','C','C','C','C','C','C','C','C','W'},
		{'W','C','C','C','C','C','C','C','C','C','C','C','C','C','C','W'},
		{'W','C','C','C','C','C','C','C','C','C','C','C','C','C','C','W'},
		{'W','C','C','C','C','C','C','C','C','C','C','C','C','C','C','W'},
		{'W','C','C','C','C','C','C','C','C','C','C','C','C','C','C','W'},
		{'W','C','C','C','C','C','C','C','C','C','C','C','C','C','C','W'},
		{'W','C','C','C','C','C','C','C','C','C','C','C','C','C','C','W'},
		{'W','C','C','C','C','C','C','C','C','C','C','C','C','C','C','W'},
		{'W','C','C','C','C','C','C','C','C','C','C','C','C','C','C','W'},
		{'W','C','C','C','C','C','C','C','C','C','C','C','C','C','C','W'},
		{'W','C','C','C','C','C','C','C','C','C','C','C','C','C','C','W'},
		{'W','C','m','C','C','C','C','C','C','C','C','C','C','C','C','W'},
		{'W','C','C','C','C','C','C','C','C','C','C','C','C','C','C','W'},
		{'W','C','C','C','C','C','C','C','C','C','C','C','C','C','C','W'},
		{'W','C','C','C','C','C','C','C','C','C','C','C','C','C','C','W'},
		{'W','C','C','C','C','C','C','C','C','C','C','C','C','C','C','W'},
		{'W','W','W','W','W','W','W','W','d','W','W','W','W','W','W','W'},
		{nil,nil,nil,nil,nil,nil,nil,nil,'d',nil,nil,nil,nil,nil,nil,nil},
	},
}
	
mobs.generate_random_vault = function(p, dir, pr)
	seed = pr:next()
	local vault_def = mobs.vault_defs[pr:next(1, #mobs.vault_defs)]
	mobs.generate_vault(vault_def, p, dir, seed)
end

local generate_corridor = function(from, to, seed)
	local pr = PseudoRandom(seed+92384)
	local p = {x=from.x, y=from.y, z=from.z}
	local step = 0
	while p.x ~= to.x do
		if step >= 5 and minetest.env:get_node(p).name == "air" then
			return
		end
		step = step + 1
		mobs.make_vault_part(p, 'C', pr)
		if p.x > to.x then
			p.x = p.x - 1
		else
			p.x = p.x + 1
		end
	end
	local step = 0
	while p.z ~= to.z do
		if step >= 5 and minetest.env:get_node(p).name == "air" then
			return
		end
		step = step + 1
		mobs.make_vault_part(p, 'C', pr)
		if p.z > to.z then
			p.z = p.z - 1
		else
			p.z = p.z + 1
		end
	end
end

minetest.register_on_generated(function(minp, maxp, seed)
	--[[if minp.x > maxp.x or minp.y > maxp.y or minp.z > maxp.z then
		mobs.debug"foo")
		return
	end--]]
	if minp.y > DUNGEON_Y or maxp.y < DUNGEON_Y then
		return
	end
	local area = (maxp.x-minp.x+1)*(maxp.z-minp.z+1)

	local possible_entrances = {}

	local entrance = {
		p = {x=0, y=-DUNGEON_Y, z=-5},
		dir = {x=0, y=0, z=1},
	}
	table.insert(possible_entrances, entrance)

	local pr = PseudoRandom(seed+931)
	for i=0,area/300 do
		local p1 = {
			x = pr:next(minp.x, maxp.x),
			y = DUNGEON_Y,
			z = pr:next(minp.z, maxp.z),
		}
		local entrance = {
			p = p1,
			dir = {x=0, y=0, z=1},
		}
		table.insert(possible_entrances, entrance)
	end

	local pr = PseudoRandom(seed+9322)
	local lastp = nil
	if minp.x < 0 and maxp.x > 0 and minp.z < 0 and maxp.z > 0 then
		lastp = {x=0, y=DUNGEON_Y, z=0}
	end
	for i,entrance in ipairs(possible_entrances) do
		--mobs.debug("Entrance: "..dump(entrance))
		mobs.generate_random_vault(entrance.p, entrance.dir, pr)
		if lastp then
			generate_corridor(lastp, entrance.p, pr:next())
		end
		lastp = entrance.p
	end
	if minp.x < 0 and maxp.x > 0 and minp.z < 0 and maxp.z > 0 then
		p = {x=0, y=DUNGEON_Y+2, z=0}
		minetest.env:set_node(p, {name="default:torch"})
	end
end)

local function give_initial_stuff(player)
	player:get_inventory():add_item('main', 'default:torch 99')
	--player:get_inventory():add_item('main', 'default:shovel_steel')
	--player:get_inventory():add_item('main', 'default:sword_steel')
	--player:get_inventory():add_item('main', 'default:cobble 99')
end

minetest.register_on_newplayer(function(player)
	player:setpos({x=0, y=DUNGEON_Y, z=0})
	give_initial_stuff(player)
end)
minetest.register_on_respawnplayer(function(player)
	player:setpos({x=0, y=DUNGEON_Y, z=0})
	player:get_inventory():set_list("main", {})
	player:get_inventory():set_list("craft", {})
	give_initial_stuff(player)
	return true
end)

