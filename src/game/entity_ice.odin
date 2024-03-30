package game

import rl "vendor:raylib"
import "core:fmt"

Ice :: struct {
	position: Vector2,
	size: Vector2,
	friction: f32
}

ice_definition :: EntityDefinition(Ice) {

	update = ice_update,
	draw = ice_draw,
}

create_ice :: proc(_position: Vector2, _size: Vector2, _friction:f32) -> ^Ice 
{
	using ice := new(Ice)
	position = _position
	size = _size
	friction = _friction

	register_entity(ice)
	return ice
}

ice_update :: proc(using _ice: ^Ice, dt: f32) {	
	_agents := get_entities(Agent)

	// for _agent in _agents
	// {
	// 	if (_agent.is_alive && collision_aabb_aabb(ice_aabb(_ice), agent_aabb(_agent)))
	// 	{
	// 		_agent.friction = friction
	// 	}
	// 	else
	// 	{
	// 		_agent.friction = 1
	// 	}
	// }
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