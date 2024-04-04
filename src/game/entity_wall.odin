package game

import rl "vendor:raylib"
import "core:fmt"

Wall :: struct {
	using entity: Entity,

	size: Vector2,
	collider: ^Collider,
}

wall_definition :: EntityDefinition(Wall) {
	draw = wall_draw,
	shutdown = wall_shutdown,
}

create_wall :: proc(_position: Vector2, _size: Vector2) -> ^Wall 
{
	using _wall := new(Wall)
	entity.type = _wall
	entity.position = _position

	size = _size
	collider = create_collider(
		_wall,
		AABB{{0,0},_size},
		.Wall,
		.Static,
	)

	register_entity(_wall)
	return _wall
}

wall_shutdown :: proc(using _wall: ^Wall)
{
	destroy_collider(collider)
}

wall_aabb :: proc(using _wall: ^Wall) -> AABB
{
	return  AABB{min=entity.position, max=entity.position+size}
}

wall_draw :: proc(using _wall: ^Wall) 
{
	x, y : i32 = floor_to_int(entity.position.x), floor_to_int(entity.position.y)
	w, h : i32 = floor_to_int(size.x), floor_to_int(size.y)
	rl.DrawRectangle(x, y, w, h, rl.DARKGRAY)
}