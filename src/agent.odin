package main

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

agent_update :: proc(using _agent : ^Agent)
{
	draw(int(position.y), _agent, proc(_payload : rawptr)
	{
		using agent := cast(^Agent)_payload
	
		x, y : i32 = i32(position.x), i32(position.y)
		rl.DrawPixel(x, y, rl.GREEN)
		rl.DrawPixel(x, y-1, rl.PINK)
		rl.DrawPixel(x+1, y, rl.DARKGRAY)	
	})
}
