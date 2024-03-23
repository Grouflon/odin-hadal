package main
import rl "vendor:raylib"
import "core:fmt"

LaserManager :: struct {
	using Manager(Laser),
}

laser_manager_initialize :: proc(using _manager: ^LaserManager)
{
	update = laser_update
	draw = laser_draw
	destroy_entity = destroy_laser
	manager_initialize(Laser, _manager)
}

laser_manager_shutdown :: proc(using _manager: ^LaserManager) 
{
	manager_shutdown(Laser, _manager)
}

Laser :: struct {
	position: Vector2,
	target: Vector2,
	owner: rawptr,
	time: f32
}

create_laserd:: proc(_position: Vector2, _target: Vector2, _owner: rawptr)
{
	 create_laser(_position, _position+_target, _owner)
}

create_laser :: proc(_position: Vector2, _target: Vector2, _owner: rawptr) -> ^Laser 
{
	using laser := new(Laser)
	position = _position
	target = _target
	owner = _owner
	time = 0

	manager_register_entity(Laser, &game().laser_manager, laser)

	return laser
}

destroy_laser:: proc(_laser: ^Laser)
{
	manager_unregister_entity(Laser, &game().laser_manager, _laser)
	free(_laser)
}


laser_update :: proc(using _laser: ^Laser, dt: f32) {	
	_agents := game().agent_manager.entities
	time+=dt

	for _agent in _agents
	{
		collide := rl.CheckCollisionPointLine(_agent.position, position, target, 1)
		if (_agent.is_alive && collide)
		{
			agent_kill(_agent)
			return
		}
	}

	if (time >= 3)
	{
		destroy_laser(_laser)
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