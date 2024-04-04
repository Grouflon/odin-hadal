package game

import rl "vendor:raylib"

Swarm :: struct {
	using entity: Entity,
}

swarm_definition :: EntityDefinition(Swarm) {
	update = swarm_update,
	draw = swarm_draw,
}

create_swarm :: proc(_position: Vector2) -> ^Swarm
{
	using _swarm := new(Swarm)
	entity.type = _swarm
	entity.position = _position

	register_entity(_swarm)

	return _swarm
}

swarm_update :: proc(using _swarm: ^Swarm, _dt: f32)
{
	_target: = find_closest_agent(entity.position, 256.0)

	if _target != nil
	{
		_direction: = normalize(_target.position - entity.position)

		_movement: = _direction * game_settings.swarm_speed * _dt 
		entity.position += _movement
	}
}

swarm_draw :: proc(using _swarm: ^Swarm)
{
	ordered_draw(int(entity.position.y), _swarm, proc(_payload: rawptr)
	{
		using _swarm := cast(^Swarm)_payload
		
		x, y : = floor_to_int(entity.position.x), floor_to_int(entity.position.y)
	    rl.DrawTexture(resources().swarm_texture, x-8, y-16, rl.WHITE)
	})
}
