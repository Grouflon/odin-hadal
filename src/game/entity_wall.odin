package game

import rl "vendor:raylib"
import "core:fmt"

Wall :: struct {
	position: Vector2,
	size: Vector2,
}

wall_definition :: EntityDefinition(Wall) {
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