package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

Selection :: struct
{
	hovered_agents: [dynamic]^Agent,
	selected_agents: [dynamic]^Agent,
	is_selecting: bool,
	start: Vector2,
	aabb: AABB
}

make_selection :: proc() -> ^Selection
{
	_selection: = new(Selection)
	return _selection
}

delete_selection :: proc(_selection: ^Selection)
{
	assert(_selection != nil)

	delete(_selection.hovered_agents)
	delete(_selection.selected_agents)
	free(_selection)
}

selection_update :: proc(using _selection: ^Selection)
{
	mouse_position : Vector2 = mouse().world_position;
	aabb = {
		mouse_position,
		mouse_position,
	}

	if (mouse().pressed[0])
	{
		is_selecting = true
		start = mouse_position
	}

	if (is_selecting)
	{
		aabb.min = start
	}
	
	aabb = {
		{
			math.floor(min(aabb.min.x ,aabb.max.x)),
			math.floor(min(aabb.min.y ,aabb.max.y)),	
		},
		{
			math.floor(max(aabb.min.x ,aabb.max.x)),
			math.floor(max(aabb.min.y, aabb.max.y)),
		}}

	clear(&hovered_agents)
	_selectable_agents: [dynamic]^Agent
	
	for _agent in game().agent_manager.entities
	{
		if collision_aabb_aabb(aabb, agent_aabb(_agent))
		{
			append(&_selectable_agents, _agent)
		}
	}

	sort(&_selectable_agents, proc(_a: ^Agent, _b: ^Agent) -> int
	{
		_mouse_position: = mouse().world_position
		_a_dist: f32 = distance_squared(_mouse_position, _a.position)
		_b_dist: f32 = distance_squared(_mouse_position, _b.position)
		return compare(_a_dist, _b_dist)
	})

	if len(_selectable_agents) > 0
	{
		if is_selecting && distance_squared(mouse_position, start) >= 1
		{
			hovered_agents = _selectable_agents
		}
		else
		{
			append(&hovered_agents, _selectable_agents[0])
		}
	}
	if mouse().released[0]
	{
		selected_agents = hovered_agents
		clear(&hovered_agents)
		is_selecting=false
	}
}

selection_draw :: proc(using _selection: ^Selection)
{
	if (!is_selecting) 
	{
		return
	}

	_draw_start: Vector2 = aabb.min
	_draw_size: Vector2 = aabb.max - _draw_start
	rl.DrawRectangleLines(i32(_draw_start.x), i32(_draw_start.y), i32(_draw_size.x), i32(_draw_size.y), rl.WHITE)
}
