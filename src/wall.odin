package main
import rl "vendor:raylib"
import "core:fmt"

Wall :: struct {
	position: Vector2,
	size: Vector2,
	friction: f32
}

wall_definition :: EntityDefinition(Wall) {
	update = wall_update,
	draw = wall_draw,
}

create_wall :: proc(_position: Vector2, _size: Vector2) -> ^Wall 
{
	using wall := new(Wall)
	position = _position
	size = _size

	register_entity(wall)
	return wall
}

wall_update :: proc(using _wall: ^Wall, dt: f32) {	
	_agents := get_entities(Agent)

	for _agent in _agents
	{
	}
}

wall_aabb :: proc(using wall: ^Wall) -> AABB
{
	return  AABB{min=position, max=position+size}
}

wall_draw :: proc(using _wall: ^Wall) 
{
	x, y : i32 = floor_to_int(position.x), floor_to_int(position.y)
	w, h : i32 = floor_to_int(size.x), floor_to_int(size.y)
	rl.DrawRectangle(x, y, w, h, rl.DARKGRAY)
}