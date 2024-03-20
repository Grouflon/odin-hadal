package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

AgentManager :: struct
{
	entities : [dynamic]^Agent,

	registered : proc(e : ^Agent),
	unregistered : proc(e : ^Agent),
	update : proc(e : ^Agent),
}

make_agent_manager :: proc() -> ^AgentManager
{
	manager := new(AgentManager)
	manager.update = agent_update

	return manager	
}

delete_agent_manager :: proc(_manager: ^AgentManager)
{
	delete(_manager.entities)
	free(_manager)
}

Agent :: struct
{
	position : Vector2,
}

make_agent :: proc(_position : Vector2) -> ^Agent
{
	agent := new(Agent)
	agent.position = _position

	return agent
}

delete_agent :: proc(_agent: ^Agent)
{
	free(_agent)
}

agent_update :: proc(using _agent : ^Agent)
{
	draw(int(position.y), _agent, proc(_payload : rawptr)
	{
		using agent := cast(^Agent)_payload
	
		x, y : i32 = floor_to_int(position.x), floor_to_int(position.y)
		rl.DrawPixel(x, y, rl.GREEN)
		rl.DrawPixel(x, y-1, rl.PINK)
		rl.DrawPixel(x+1, y, rl.DARKGRAY)	
	})
}

agent_aabb :: proc(using _agent: ^Agent) -> AABB
{
	x, y : f32 = math.floor(position.x), math.floor(position.y)
	return AABB {
		{ x, y-1 },
		{ x+1, y+1 },
	}

}
