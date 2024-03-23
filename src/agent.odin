package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

AgentManager :: struct
{
	entities : [dynamic]^Agent,

	registered : proc(e : ^Agent),
	unregistered : proc(e : ^Agent),
	update : proc(e : ^Agent, dt: f32),
}

agent_manager_initialize :: proc(using _manager: ^AgentManager)
{
	update = agent_update
	entities = make([dynamic]^Agent)
}

agent_manager_shutdown :: proc(using _manager: ^AgentManager)
{
	// Delete all entities that are left in the manager
	_agents: = _manager.entities
    for _i := len(_agents) - 1; _i >= 0; _i-=1 
    {
    	_agent: = _agents[_i]
    	agent_shutdown(_agent)
		manager_unregister_entity(_manager, _agent)
        delete_agent(_agent)
    }

	delete(_agents)
}

Agent :: struct
{
	position : Vector2,
	is_alive : bool
}

make_agent :: proc() -> ^Agent
{
	return new(Agent)
}

delete_agent :: proc(_agent: ^Agent)
{
	free(_agent)
}

agent_initialize :: proc(using _agent: ^Agent, _position : Vector2)
{
	position = _position
	is_alive = true
}

agent_shutdown :: proc(using _agent: ^Agent)
{
}

agent_update :: proc(using _agent : ^Agent, dt: f32)
{
	if (is_alive && game().mouse.down[1])
	{
		wp:= game().mouse.world_position
		direction := normalize(wp - position)
		speed: f32= 10.0
		position +=  direction * dt  * speed
	}

	draw(int(position.y), _agent, agent_draw)
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

agent_draw :: proc(_payload: rawptr)
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