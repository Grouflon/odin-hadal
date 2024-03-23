package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

AgentManager :: struct
{
	using Manager(Agent),
}

agent_manager_initialize :: proc(using _manager: ^AgentManager)
{
	update = agent_update
	draw = agent_draw
	destroy_entity = destroy_agent
	manager_initialize(Agent, _manager)
}

agent_manager_shutdown :: proc(using _manager: ^AgentManager)
{
	manager_shutdown(Agent, _manager)
}

Agent :: struct
{
	position : Vector2,
	velocity : Vector2,
	is_alive : bool,
	friction : f32
}

create_agent :: proc(_position : Vector2) -> ^Agent
{
	using _agent: = new(Agent)

	position = _position
	is_alive = true
	friction = 1

	manager_register_entity(Agent, &game().agent_manager, _agent)
	return _agent
}

destroy_agent :: proc(using _agent: ^Agent)
{
	manager_unregister_entity(Agent, &game().agent_manager, _agent)
	free(_agent)
}


agent_update :: proc(using _agent : ^Agent, dt: f32)
{
	if (is_alive && game().mouse.down[1])
	{
		wp:= game().mouse.world_position
		speed: f32= 10.0
		velocity = normalize(wp - position) * speed
		position += velocity * dt
 
	}
	else if (friction != 1)
	{
		if (length(velocity) > 0)
		{
			velocity = velocity * TimeIndependentLerp2(1, 0, 0.2, dt)
			position += velocity

		}
	}

}

TimeIndependentLerp2 :: proc(_base:f32,_target:f32, _timeTo90:f32, _dt:f32) -> f32
{
	lambda := -math.log10_f32(1 - 0.9) / _timeTo90;
	return math.lerp(_base, _target, 1 - math.exp_f32(-lambda * _dt));
}

agent_draw :: proc(using _agent: ^Agent)
{
	ordered_draw(int(position.y), _agent, proc(_payload: rawptr)
	{
		using agent := cast(^Agent)_payload
		
		x, y : i32 = floor_to_int(position.x), floor_to_int(position.y)
		
		if (is_alive)
		{
			rl.DrawPixel(x, y-1, rl.PINK)
			rl.DrawPixel(x+1, y, rl.DARKGRAY)	
		} 
		else
		{
			rl.DrawEllipse(
				x,
				y,
				3,
				2,
				rl.RED)
				rl.DrawPixel(x-1, y, rl.PINK)
			}
		rl.DrawPixel(x, y, rl.GREEN)
	})
}

agent_kill :: proc(using _agent: ^ Agent)
{
	hover := game().selection.hovered_agents
	index := find(&hover, _agent)
	if (index >= 0)
	{
		unordered_remove(&hover, index)
	}
	
	selected := game().selection.selected_agents
	index_select := find(&selected, _agent)
	if (index_select >= 0)
	{
		unordered_remove(&selected, index_select)
	}

	is_alive = false
}

agent_aabb :: proc(using _agent: ^Agent) -> AABB
{
	x, y : f32 = math.floor(position.x), math.floor(position.y)
	return AABB {
		{ x, y-1 },
		{ x+1, y+1 },
	}
}

find_closest_agent :: proc(_position: Vector2, _range:f32) -> ^Agent
{
	_agents := game().agent_manager.entities
	_closest_agent : ^Agent = nil
	_range_temp := _range
	for _agent in _agents
	{
		if (!_agent.is_alive ){ continue }

		_dist := distance(_position, _agent.position)

		if (_dist < _range)
		{
			_closest_agent = _agent
			_range_temp = _dist
		}
	}

	return _closest_agent
}