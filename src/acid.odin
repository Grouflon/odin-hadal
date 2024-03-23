package main
import rl "vendor:raylib"
import "core:fmt"

AcidManager :: struct {
	using Manager(Acid),
}

acid_manager_initialize :: proc(using _manager: ^AcidManager)
{
	update = acid_update
	draw = acid_draw
	destroy_entity = destroy_acid
	manager_initialize(Acid, _manager)
}

acid_manager_shutdown :: proc(using _manager: ^AcidManager) 
{
	manager_shutdown(Acid, _manager)
}

Acid :: struct {
	position: Vector2,
	size: Vector2,
}

create_acid :: proc(_position: Vector2, _size: Vector2) -> ^Acid 
{
	using acid := new(Acid)
	position = _position
	size = _size

	manager_register_entity(Acid, &game().acid_manager, acid)
	return acid
}

destroy_acid:: proc(_acid: ^Acid)
{
	manager_unregister_entity(Acid, &game().acid_manager, _acid)
	free(_acid)
}


acid_update :: proc(using _acid: ^Acid, dt: f32) {	
	_agents := game().agent_manager.entities

	aabb := AABB{min=position, max=position+size }

	for _agent in _agents
	{
		if (_agent.is_alive && collision_aabb_aabb(aabb, agent_aabb(_agent)))
		{
			agent_kill(_agent)
			return
		}
	}
}

acid_draw :: proc(using _acid: ^Acid) 
{
	x, y : i32 = floor_to_int(position.x), floor_to_int(position.y)
	w, h : i32 = floor_to_int(size.x), floor_to_int(size.y)
	rl.DrawRectangle(x, y, w, h, rl.GREEN)
}