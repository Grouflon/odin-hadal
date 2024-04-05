package game

import rl "vendor:raylib"
import "core:fmt"

Ice :: struct {
	using entity: Entity,
	
	size: Vector2,
	friction: f32
}

ice_definition :: EntityDefinition(Ice) {

	draw = ice_draw,
}

create_ice :: proc(_position: Vector2, _size: Vector2, _friction:f32) -> ^Ice 
{
	using ice := new(Ice)
	entity.type = ice
	entity.position = _position
	
	size = _size
	friction = _friction

	register_entity(ice)
	return ice
}

ice_aabb :: proc(using ice: ^Ice) -> AABB
{
	return  AABB{min=entity.position, max=entity.position+size}
}

ice_draw :: proc(using _ice: ^Ice) 
{
	x, y : i32 = floor_to_int(entity.position.x), floor_to_int(entity.position.y)
	w, h : i32 = floor_to_int(size.x), floor_to_int(size.y)
	rl.DrawRectangle(x, y, w, h, rl.BLUE)
}