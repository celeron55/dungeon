-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file mov_gen_none.lua
--! @brief a dummy movement gen
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

--! @class mgen_none
--! @brief a movement generator doing nothing
mgen_none = {}

--!@}

--! @brief movement generator identifier
--! @memberof mgen_none
mgen_none.name = "none"

-------------------------------------------------------------------------------
-- name: callback(entity,now)
--
--! @brief main callback to do nothing
--! @memberof mgen_none
--
--! @param entity mob to generate movement for
--! @param now current time
-------------------------------------------------------------------------------
function mgen_none.callback(entity,now)
    local pos = entity.getbasepos(entity)
    local speed = entity.object:getvelocity()
    local default_y_acceleration = environment.get_default_gravity(pos,
                                            entity.environment.media,
                                            entity.data.movement.canfly)
                                            
    entity.object:setacceleration({x=0,y=default_y_acceleration,z=0})
    entity.object:setvelocity({x=0,y=speed.y,z=0})
    
end

-------------------------------------------------------------------------------
-- name: initialize()
--
--! @brief initialize movement generator
--! @memberof mgen_none
--! @public
-------------------------------------------------------------------------------
function mgen_none.initialize(entity,now)
end

-------------------------------------------------------------------------------
-- name: init_dynamic_data(entity,now)
--
--! @brief initialize dynamic data required by movement generator
--! @memberof mgen_none
--! @public
--
--! @param entity mob to initialize dynamic data
--! @param now current time
-------------------------------------------------------------------------------
function mgen_none.init_dynamic_data(entity,now)

    local data = {
            moving = false,
            }
    
    entity.dynamic_data.movement = data
end

--register this movement generator
registerMovementGen(mgen_none.name,mgen_none)