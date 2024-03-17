package main

import rl "vendor:raylib"

Agent :: struct
{
	using entity : Entity

}

make_agent :: proc(_position : rl.Vector2) -> ^Agent
{
	agent := new(Agent)
	agent.position = _position

	agent.update = agent_update
	agent.draw = agent_draw

	return agent
}

agent_update :: proc(_entity : ^Entity)
{
	using agent := cast(^Agent)_entity
}

agent_draw :: proc(_entity : ^Entity)
{
	using agent := cast(^Agent)_entity
	
	x, y : i32 = i32(position.x), i32(position.y)
	rl.DrawPixel(x, y, rl.GREEN)
	rl.DrawPixel(x, y-1, rl.PINK)
	rl.DrawPixel(x+1, y, rl.DARKGRAY)
}

