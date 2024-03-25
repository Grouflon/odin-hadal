package main
import rl "vendor:raylib"
import "core:fmt"

Acid :: struct {
	position: Vector2,
	size: Vector2,
}

acid_definition :: EntityDefinition(Acid) {
	update = acid_update,
	draw = acid_draw,
}

create_acid :: proc(_position: Vector2, _size: Vector2) -> ^Acid 
{
	using acid := new(Acid)
	position = _position
	size = _size

	register_entity(acid)
	return acid
}

acid_update :: proc(using _acid: ^Acid, _dt: f32)
{	
	_agents := get_entities(Agent)

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