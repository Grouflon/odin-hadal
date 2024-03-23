package main
import rl "vendor:raylib"
import "core:fmt"

IceManager :: struct {
	using Manager(Ice),
}

ice_manager_initialize :: proc(using _manager: ^IceManager)
{
	update = ice_update
	draw = ice_draw
	destroy_entity = destroy_ice
	manager_initialize(Ice, _manager)
}

ice_manager_shutdown :: proc(using _manager: ^IceManager) 
{
	manager_shutdown(Ice, _manager)
}

Ice :: struct {
	position: Vector2,
	size: Vector2,
	friction: f32
}

create_ice :: proc(_position: Vector2, _size: Vector2, _friction:f32) -> ^Ice 
{
	using ice := new(Ice)
	position = _position
	size = _size
	friction = _friction

	manager_register_entity(Ice, &game().ice_manager, ice)
	return ice
}

destroy_ice:: proc(_ice: ^Ice)
{
	manager_unregister_entity(Ice, &game().ice_manager, _ice)
	free(_ice)
}


ice_update :: proc(using _ice: ^Ice, dt: f32) {	
	_agents := game().agent_manager.entities

	for _agent in _agents
	{
		if (_agent.is_alive && collision_aabb_aabb(ice_aabb(_ice), agent_aabb(_agent)))
		{
			_agent.friction = friction
		}
		else
		{
			_agent.friction = 1
		}
	}
}

ice_aabb :: proc(using ice: ^Ice) -> AABB
{
	return  AABB{min=position, max=position+size}
}

ice_draw :: proc(using _ice: ^Ice) 
{
	x, y : i32 = floor_to_int(position.x), floor_to_int(position.y)
	w, h : i32 = floor_to_int(size.x), floor_to_int(size.y)
	rl.DrawRectangle(x, y, w, h, rl.BLUE)
}