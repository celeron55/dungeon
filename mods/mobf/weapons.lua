-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file weapons.lua
--! @brief weapon related functions
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--
--! @defgroup weapons Weapons
--! @brief weapon entitys predefined by mob framework (can be extended by mod)
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

local weapons_spacer = {} --unused to fix lua doxygen bug only

-------------------------------------------------------------------------------
-- name: mobf_init_weapons = function(self, dtime)
--
--! @brief initialize weapons handled by mobf mod
--
-------------------------------------------------------------------------------
function mobf_init_weapons()
	minetest.register_entity(":mobf:fireball_entity", MOBF_FIREBALL_ENTITY)
	minetest.register_entity(":mobf:plasmaball_entity", MOBF_PLASMABALL_ENTITY)
end

-------------------------------------------------------------------------------
-- name: mobf_do_area_damage(pos,immune,damage,range) 
--
--! @brief damage all objects within a certain range
--
--! @param pos cennter of damage area
--! @param immune object immune to damage
--! @param damage damage to be done
--! @param range range around pos
-------------------------------------------------------------------------------
function mobf_do_area_damage(pos,immune,damage,range)
	--damage objects within inner blast radius
	objs = minetest.env:get_objects_inside_radius(pos, range)
	for k, obj in pairs(objs) do

		--don't do damage to issuer
		if obj ~= immune then
			obj:set_hp(obj:get_hp()-damage)
		end
	end
end


-------------------------------------------------------------------------------
-- name: mobf_do_node_damage(pos,immune_list,range,chance)
--
--! @brief damage all nodes within a certain range
--
--! @param pos center of area
--! @param immune_list list of nodes immune to damage
--! @param range range to do damage
--! @param chance chance damage is done to a node
-------------------------------------------------------------------------------
function mobf_do_node_damage(pos,immune_list,range,chance)
	--do node damage
	for i=pos.x-range, pos.x+range, 1 do
		for j=pos.y-range, pos.y+range, 1 do
			for k=pos.z-range,pos.z+range,1 do
				--TODO create a little bit more sophisticated blast resistance
				if math.random() < chance then
					local toremove = minetest.env:get_node({x=i,y=j,z=k})

					if toremove ~= nil then
						local immune = false
					
						if immune_list ~= nil then
							for i,v in ipairs(immune_list) do
								if (torremove.name == v) then
									immune = true
								end
							end
						end


						if immune ~= true then					
							minetest.env:remove_node({x=i,y=j,z=k})
						end
					end
				end
			end
		end
	end
end

--! @class MOBF_FIREBALL_ENTITY
--! @ingroup weapons
--! @brief a fireball weapon entity
MOBF_FIREBALL_ENTITY = {
	physical = false,
	textures = {"animals_fireball.png"},
	collisionbox = {0,0,0,0,0,0},

	damage_range = 4,
	velocity = 3,
	gravity = -0.01,

	damage = 15,

	owner = 0,
	lifetime = 30,
	created = -1,
}


-------------------------------------------------------------------------------
-- name: MOBF_FIREBALL_ENTITY.on_activate = function(self, staticdata)
--
--! @brief onactivate callback for fireball
--! @memberof MOBF_FIREBALL_ENTITY
--! @private
--
--! @param self fireball itself
--! @param staticdata 
-------------------------------------------------------------------------------
function MOBF_FIREBALL_ENTITY.on_activate(self,staticdata)
	self.created = mobf_get_current_time()
end

-------------------------------------------------------------------------------
-- name: MOBF_FIREBALL_ENTITY.surfacefire = function(self, staticdata)
--
--! @brief place fire on surfaces around pos
--! @memberof MOBF_FIREBALL_ENTITY
--! @private
--
--! @param pos position to place fire around
--! @param range square around pos to set on fire
-------------------------------------------------------------------------------
function MOBF_FIREBALL_ENTITY.surfacefire(pos,range)

	if mobf_rtd.fire_enabled then
		--start fire on any surface within inner damage range
		for i=pos.x-range/2, pos.x+range/2, 1 do
		for j=pos.y-range/2, pos.y+range/2, 1 do
		for k=pos.z-range/2, pos.z+range/2, 1 do
		
			local current = minetest.env:get_node({x=i,y=j,z=k})
			local ontop  = minetest.env:get_node({x=i,y=j+1,z=k})
			
			--print("put fire? " .. printpos({x=i,y=j,z=k}) .. " " .. current.name .. " " ..ontop.name)
			
			if (current.name ~= "air") and
				(current.name ~= "fire:basic_flame") and
				(ontop.name == "air") then
				minetest.env:set_node({x=i,y=j+1,z=k}, {name="fire:basic_flame"})
			end
					
		end
		end
		end
	else
		minetest.log(LOGLEVEL_ERROR,"MOBF: A fireball without fire mod??!? You're kidding!!")
	end
end

-------------------------------------------------------------------------------
-- name: MOBF_FIREBALL_ENTITY.on_step = function(self, dtime)
--
--! @brief onstep callback for fireball
--! @memberof MOBF_FIREBALL_ENTITY
--! @private
--
--! @param self fireball itself
--! @param dtime time since last callback
-------------------------------------------------------------------------------
function MOBF_FIREBALL_ENTITY.on_step(self, dtime)
	local pos = self.object:getpos()
	local node = minetest.env:get_node(pos)


	--detect hit
	local objs=minetest.env:get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, 1)

	local hit = false

	for k, obj in pairs(objs) do
		if obj:get_entity_name() ~= "mobf:fireball_entity" and
			obj ~= self.owner then
			hit=true
		end
	end


	if hit then
		--damage objects within inner blast radius
		mobf_do_area_damage(pos,self.owner,self.damage_range/4,self.damage/4)

		--damage all objects within blast radius
		mobf_do_area_damage(pos,self.owner,self.damage_range/2,self.damage/2)		
		
		MOBF_FIREBALL_ENTITY.surfacefire(pos,self.damage_range)

		self.object:remove()
	end

	-- vanish when hitting a node
	if node.name ~= "air" then
		MOBF_FIREBALL_ENTITY.surfacefire(pos,self.damage_range)
		self.object:remove()
	end

	--remove after lifetime has passed
	if self.created > 0 and
		self.created + self.lifetime < mobf_get_current_time() then
		self.object:remove()
	end
end


--! @class MOBF_PLASMABALL_ENTITY
--! @ingroup weapons
--! @brief a plasmaball weapon entity
MOBF_PLASMABALL_ENTITY = {
	physical = false,
	textures = {"animals_plasmaball.png"},
	lastpos={},
	collisionbox = {0,0,0,0,0,0},

	damage_range = 2,
	velocity = 4,
	gravity = -0.001,

	damage = 8,

	owner = 0,
	lifetime = 30,
	created = -1,
}

-------------------------------------------------------------------------------
-- name: MOBF_PLASMABALL_ENTITY.on_activate = function(self, staticdata)
--
--! @brief onactivate callback for plasmaball
--! @memberof MOBF_PLASMABALL_ENTITY
--! @private
--
--! @param self fireball itself
--! @param staticdata 
-------------------------------------------------------------------------------
function MOBF_PLASMABALL_ENTITY.on_activate(self,staticdata)
	self.created = mobf_get_current_time()
end


-------------------------------------------------------------------------------
-- name: MOBF_PLASMABALL_ENTITY.on_step = function(self, dtime)
--
--! @brief onstep callback for plasmaball
--! @memberof MOBF_PLASMABALL_ENTITY
--! @private
--
--! @param self plasmaball itself
--! @param dtime time since last callback
-------------------------------------------------------------------------------
function MOBF_PLASMABALL_ENTITY.on_step(self, dtime)
	local pos = self.object:getpos()
	local node = minetest.env:get_node(pos)


	--detect hit
	local objs=minetest.env:get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, 1)

	local hit = false

	for k, obj in pairs(objs) do
		if obj:get_entity_name() ~= "mobf:plasmaball_entity" and
			obj ~= self.owner then
			hit=true
		end
	end

	--damage all objects not hit but at least passed
	mobf_do_area_damage(pos,self.owner,2,1)	

	if hit then
		--damage objects within inner blast radius
		mobf_do_area_damage(pos,self.owner,self.damage_range/4,self.damage/2)

		--damage all objects within blast radius
		mobf_do_area_damage(pos,self.owner,self.damage_range/2,self.damage/2)
	end

	-- vanish when hitting a node
	if node.name ~= "air" or
		hit then

		--replace this loop by minetest.env:find_node_near?
		--do node damage
		for i=pos.x-1, pos.x+1, 1 do
			for j=pos.y-1, pos.y+1, 1 do
				for k=pos.z-1,pos.z+1,1 do
					--TODO create a little bit more sophisticated blast resistance
					if math.random() < 0.5 then
						local toremove = minetest.env:get_node({x=i,y=j,z=k})

						if toremove ~= nil and
							toremove.name ~= "default:stone" and
							toremove.name ~= "default:cobble" then
						
							minetest.env:remove_node({x=i,y=j,z=k})
						end
					end
				end
			end
		end

		self.object:remove()
	end

	--remove after lifetime has passed
	if self.created > 0 and
		self.created + self.lifetime < mobf_get_current_time() then
		self.object:remove()
	end
end
