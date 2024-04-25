package game

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

	selection_clear(_selection)

	delete(_selection.hovered_agents)
	delete(_selection.selected_agents)
	free(_selection)
}

selection_clear :: proc(using _selection: ^Selection)
{
	clear(&hovered_agents)
	clear(&selected_agents)
	is_selecting = false
}

selection_unselect_agent :: proc(using _selection: ^Selection, _agent: ^Agent)
{
	index: = find(&hovered_agents, _agent)
	if (index >= 0)
	{
		unordered_remove(&hovered_agents, index)
	}
	
	index_select: = find(&selected_agents, _agent)
	if (index_select >= 0)
	{
		unordered_remove(&selected_agents, index_select)
	}
}

selection_update :: proc(using _selection: ^Selection)
{
	// Clear non selectable agents from selection
	for i: = len(selected_agents) - 1; i >= 0; i -= 1
	{
		if (!agent_is_selectable(selected_agents[i]))
		{
			unordered_remove(&selected_agents, i)
		}
	}

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

	_selectable_agents: [dynamic]^Agent // TODO use temp allocator
	defer delete(_selectable_agents)

	for _agent in get_entities(Agent)
	{
		if agent_is_selectable(_agent) && collision_aabb_aabb(aabb, agent_aabb(_agent))
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
			copy_array(&hovered_agents, _selectable_agents[:])
		}
		else
		{
			append(&hovered_agents, _selectable_agents[0])
		}
	}
	if mouse().released[0]
	{
		for agent in selected_agents
		{
			agent.is_preview_aim = false
		}
		copy_array(&selected_agents, hovered_agents[:])
		clear(&hovered_agents)
		is_selecting=false
	}
}

selection_draw_agents :: proc(using _selection: ^Selection)
{
	using rl

	for _agent in hovered_agents
	{
		_x, _y := floor_to_int(_agent.position.x), floor_to_int(_agent.position.y)
		DrawEllipseLines(
			_x,
			_y,
			5,
			3,
			rl.RAYWHITE)
	}

	for _agent in selected_agents
	{
		_x, _y := floor_to_int(_agent.position.x), floor_to_int(_agent.position.y)
		DrawEllipseLines(
			_x,
			_y,
			5,
			3,
			rl.WHITE)
	}
}

selection_draw :: proc(using _selection: ^Selection)
{
	// rl.DrawPixel(floor_to_int(mouse().world_position.x), floor_to_int(mouse().world_position.y), rl.RED)

	if (!is_selecting) 
	{
		return
	}

	_draw_start: Vector2 = aabb.min
	_draw_size: Vector2 = aabb.max - _draw_start
	rl.DrawRectangleLines(i32(_draw_start.x), i32(_draw_start.y), i32(_draw_size.x), i32(_draw_size.y), rl.WHITE)
}
