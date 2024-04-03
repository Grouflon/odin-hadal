package game

import rl "vendor:raylib"
import "core:fmt"

Laser :: struct {
	using entity: Entity,
	
	position: Vector2,
	target: Vector2,
	owner: rawptr,
	time: f32
}

laser_definition :: EntityDefinition(Laser) {
	update = laser_update,
	draw = laser_draw,
}

create_laser_target:: proc(_position: Vector2, _target: Vector2, _owner: rawptr)
{
	 create_laser(_position, _position+_target, _owner)
}

create_laser :: proc(_position: Vector2, _target: Vector2, _owner: rawptr) -> ^Laser 
{
	using laser := new(Laser)
	entity.type = laser
	
	position = _position
	target = _target
	owner = _owner
	time = 0

	register_entity(laser)

	return laser
}

laser_update :: proc(using _laser: ^Laser, dt: f32) {	
	_agents := get_entities(Agent)
	time+=dt

	for _agent in _agents
	{
		collide := collision_line_point(_agent.position, position, target)
		if (_agent.is_alive && collide)
		{
			agent_kill(_agent)
			return
		}
	}

	if (time >= 3)
	{
		destroy_entity(_laser)
		return
	}
}

laser_draw :: proc(using _laser: ^Laser) {
	ordered_draw(int(position.y), _laser, proc(_payload: rawptr)
	{
		using laser := cast(^Laser)_payload
		rl.DrawLineV(position, target, rl.PURPLE)
	})
}