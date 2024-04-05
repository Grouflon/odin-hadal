package game

import rl "vendor:raylib"
import "core:fmt"

Goal :: struct {
	using entity: Entity,
	
	size: Vector2,
	nextLevel: i32,
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
	for _agent in _agents
	{
		collide: = collision_aabb_aabb(goal_aabb(_goal),agent_aabb(_agent))
		if (_agent.is_alive && collide)
		{

			return
		}
	}
}

goal_aabb :: proc(using goal: ^Goal) -> AABB
{
	return  AABB{min=entity.position, max=entity.position+size}
}

goal_draw :: proc(using _goal: ^Goal) 
{
	
}