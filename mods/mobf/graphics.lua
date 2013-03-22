-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file graphics.lua
--! @brief graphics related parts of mob
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

--! @class graphics
--! @brief graphic features
graphics = {}

-------------------------------------------------------------------------------
-- name: update_orientation_simple(entity,velocity)
--
--! @brief calculate direction of mob to face
--! @memberof graphics
--
--! @param entity mob to calculate direction
--! @param current_velocity data to calculate direction from
-------------------------------------------------------------------------------
function graphics.update_orientation_simple(entity,current_velocity)
	local x_abs = math.abs(current_velocity.x)
	local z_abs = math.abs(current_velocity.z)
	if x_abs > z_abs then
		if current_velocity.x > 0 then
			entity.object:setyaw(0)
		else
			entity.object:setyaw(math.pi)
		end
	else
		if current_velocity.z >0 then
			entity.object:setyaw(math.pi/2)
		else
			entity.object:setyaw(math.pi * (3/2))
		end
	end
end

-------------------------------------------------------------------------------
-- name: update_orientation(entity)
--
--! @brief callback for calculating a mobs direction
--! @memberof graphics
--
--! @param entity mob to calculate direction
--! @param now current time
--! @param dtime current dtime
-------------------------------------------------------------------------------
function graphics.update_orientation(entity,now,dtime)

	if entity.dynamic_data == nil or
		entity.dynamic_data.movement == nil then
		mobf_bug_warning(LOGLEVEL_ERROR,"MOBF BUG!!!: >" ..entity.data.name 
			.. "< removed=" .. dump(entity.removed) .. " entity=" 
			.. tostring(entity) .. " graphics callback without dynamic data")
		return
	end

	local new_orientation = 0

--	if entity.dynamic_data.movement.ts_orientation_upd + 1 < now and
	if	entity.dynamic_data.movement.orientation_fix_needed then

		dbg_mobf.graphics_lvl3("MOBF: Updating orientation")
		--entity.dynamic_data.movement.ts_orientation_upd = now

		local current_velocity = entity.object:getvelocity()
		local acceleration = entity.object:getacceleration()
		local pos = entity.getbasepos(entity)
		
		dbg_mobf.graphics_lvl3("MOBF: vel: (" .. current_velocity.x .. ",".. current_velocity.z .. ") " .. 
											"accel: (" ..acceleration.x .. "," .. acceleration.z .. ")")
		
		--predict position mob will be in 0.25 seconds
		--local predicted_pos = movement_generic.calc_new_pos(pos,acceleration,dtime,current_velocity)
			
		--local delta_x = predicted_pos.x - pos.x
		--local delta_z = predicted_pos.z - pos.z
		local delta_x = current_velocity.x
		local delta_z = current_velocity.z

		--legacy 2d mode
		if (entity.mode == "2d") then
			graphics.update_orientation_simple(entity,{x=delta_x, z=delta_z})
		-- 3d mode
		else
			
			if (delta_x ~= 0 ) and
				(delta_z ~= 0) then
				
				entity.object:setyaw(mobf_calc_yaw(delta_x,delta_z))
				
				dbg_mobf.graphics_lvl3("MOBF: x-delta: " .. delta_x 
					.. " z-delta: " .. delta_z)
			elseif (delta_x ~= 0) or
					(delta_z ~= 0) then
					dbg_mobf.graphics_lvl3("MOBF: at least speed for one direction is 0")
					graphics.update_orientation_simple(entity,{x=delta_x,z=delta_z})
			else
				dbg_mobf.movement_lvl3("MOBF: not moving")
			end
		end
	end

end

-------------------------------------------------------------------------------
-- name: set_animation(entity,name)
--
--! @brief set the drawmode for an mob entity
--! @memberof graphics
--
--! @param entity mob to set drawmode for
--! @param name name of animation
-------------------------------------------------------------------------------
function graphics.set_animation(entity,name)

	if name == nil then
		dbg_mobf.graphics_lvl2("MOBF: calling updating animation without name for " .. entity.data.name)
		return
	end

	if entity.mode == "2d" then
	
		if id == "stand" then
			entity.object:setsprite({x=0,y=0}, 1, 0, true)
		end
	
		if name == "burning" then
			entity.object:setsprite({x=0,y=1}, 1, 0, true)
		end
		
		return
	end
	
	if entity.mode == "3d" then
		--TODO change frame rate due to movement speed
		dbg_mobf.graphics_lvl2("MOBF: " .. entity.data.name .. " updating animation: " .. name)
		if entity.data.animation ~= nil and
			name ~= nil and
			entity.data.animation[name] ~= nil and
			entity.dynamic_data.animation ~= name then
			
			dbg_mobf.graphics_lvl2("MOBF:\tSetting animation to " .. name 
				.. " start: " .. entity.data.animation[name].start_frame 
				.. " end: " .. entity.data.animation[name].end_frame)
			entity.object:set_animation({
											x=entity.data.animation[name].start_frame,
											y=entity.data.animation[name].end_frame
										}, nil, nil)
			entity.dynamic_data.animation = name
		end
		
		return
	end
	
	mobf_bug_warning(LOGLEVEL_WARNING,"MOBF BUG!!: invalid graphics mode specified " 
		.. dump(entity.mode))
	
end

------------------------------------------------------------------------------
-- name: prepare_graphic_info(graphics2d,graphics3d)
--
--! @brief get graphics information
--! @memberof graphics
--
--! @param graphics2d
--! @param graphics3d
--! @param modname
--! @param name
--! @param statename
--! @return grahpic information
-------------------------------------------------------------------------------
function graphics.prepare_info(graphics2d,graphics3d,modname,name,statename)

	local setgraphics = {}
	
	

	if (graphics3d == nil) or
		minetest.setting_getbool("mobf_disable_3d_mode") then
		if (graphics2d == nil) then
			--this maybe correct if there's a state model requested!
			return nil
		end
		
		local basename = modname .. name
	
		if statename ~= nil and
			statename ~= "default" then
			basename = basename .. "__" .. statename
		end
		
		setgraphics.collisionbox    =  {-0.5,
									-0.5 * graphics2d.visible_height,
									-0.5,
									0.5,
									0.5 * graphics2d.visible_height,
									0.5}
		if graphics2d.visual ~= nil then
			setgraphics.visual          = graphics2d.visual
		else
			setgraphics.visual          = "sprite"
		end
		setgraphics.textures        = { basename..".png^[makealpha:128,0,0^[makealpha:128,128,0" }
		setgraphics.visual_size     = graphics2d.sprite_scale
		setgraphics.spritediv       = graphics2d.sprite_div
		setgraphics.mode 			= "2d"
	else
		if graphics3d.visual == "mesh" then
			setgraphics.mesh = graphics3d.mesh
		end
		
		setgraphics.collisionbox    = graphics3d.collisionbox --todo is this required for mesh?
		setgraphics.visual          = graphics3d.visual
		setgraphics.visual_size     = graphics3d.visual_size
		setgraphics.textures        = graphics3d.textures
		setgraphics.mode 			= "3d"
	end
	
	return setgraphics
end