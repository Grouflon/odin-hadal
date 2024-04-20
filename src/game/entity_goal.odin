package game

import rl "vendor:raylib"
import "core:fmt"

Goal :: struct {
	using entity: Entity,
	
	size: Vector2,
	nextLevel: i32,
	mouse_hover: bool
}

goal_definition :: EntityDefinition(Goal) {
	update = goal_update,
	draw = goal_draw,
}

create_goal :: proc(_position: Vector2, _size: Vector2, _nextLevel: i32) -> ^Goal 
{
	using goal := new(Goal)
	entity.type = goal

	entity.position = _position
	size = _size
	nextLevel = _nextLevel

	register_entity(goal)
	return goal
}

goal_update :: proc(using _goal: ^Goal, dt: f32)
{
	_agents: = get_entities(Agent)
	mouse_position: = game().mouse.world_position

	mouse_AABB: = AABB{min=mouse_position, max=mouse_position}
	mouse_hover = collision_aabb_aabb(goal_aabb(_goal),mouse_AABB)

	if (game().mouse.pressed[1] && mouse_hover)
	{
		switch_level_to(nextLevel)
	}
}

goal_aabb :: proc(using goal: ^Goal) -> AABB
{
	return  AABB{min=entity.position, max=entity.position+size}
}

goal_draw :: proc(using _goal: ^Goal) 
{
	ordered_draw(-1, _goal, proc(_payload: rawptr)
	{
		using goal: = cast(^Goal)_payload
		using rl

		if (mouse_hover)
		{
			DrawRectangleLines(
				floor_to_int(goal.position.x), 
				floor_to_int(goal.position.y), 
				floor_to_int(size.x),
				floor_to_int(size.y), GREEN)
		}

		DrawText("EXIT", i32(goal.position.x), i32(goal.position.y), 5, BLACK)

	})
}