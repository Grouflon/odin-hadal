package main
import rl "vendor:raylib"
import "core:fmt"

WallManager :: struct {
	using Manager(Wall),
}

wall_manager_initialize :: proc(using _manager: ^WallManager)
{
	update = wall_update
	draw = wall_draw
	destroy_entity = destroy_wall
	manager_initialize(Wall, _manager)
}

wall_manager_shutdown :: proc(using _manager: ^WallManager) 
{
	manager_shutdown(Wall, _manager)
}

Wall :: struct {
	position: Vector2,
	size: Vector2,
	friction: f32
}

create_wall :: proc(_position: Vector2, _size: Vector2) -> ^Wall 
{
	using wall := new(Wall)
	position = _position
	size = _size

	manager_register_entity(Wall, &game().wall_manager, wall)
	return wall
}

destroy_wall:: proc(_wall: ^Wall)
{
	manager_unregister_entity(Wall, &game().wall_manager, _wall)
	free(_wall)
}


wall_update :: proc(using _wall: ^Wall, dt: f32) {	
	_agents := game().agent_manager.entities

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