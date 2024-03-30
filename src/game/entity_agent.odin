package game

import "core:fmt"
import "core:math"
import "core:log"
import rl "vendor:raylib"

Agent :: struct
{
	position: Vector2,
	velocity : Vector2,
	is_alive: bool,

	animation_player: ^AnimationPlayer,
}

agent_definition :: EntityDefinition(Agent) {

	update = agent_update,
	draw = agent_draw,
	shutdown = agent_shutdown,
}

create_agent :: proc(_position : Vector2) -> ^Agent
{
	using _agent: = new(Agent)

	position = _position
	is_alive = true
	animation_player = create_animation_player()

	register_entity(_agent)
	return _agent
}

agent_shutdown :: proc(using _agent: ^Agent)
{
	destroy_animation_player(animation_player)
}

agent_update :: proc(using _agent : ^Agent, _dt: f32)
{	
	_is_moving: = false

	// Velocity
	_velocity_length: = length(velocity)
	_direction: Vector2
	if (is_alive && game().mouse.down[1])
	{
		_mouse: = game().mouse.world_position
		_direction = normalize(_mouse - position)
		_velocity_length += game_settings.agent_acceleration * _dt
		_velocity_length = math.min(_velocity_length, game_settings.agent_max_speed)
	}
	else
	{
		_direction = normalize(velocity)
		_velocity_length -= game_settings.agent_deceleration * _dt
		_velocity_length = math.max(_velocity_length, 0)
	}
	velocity = _direction * _velocity_length

	// Movement
	_movement: = velocity * _dt
	_aabb: = agent_aabb(_agent)
	for _wall in get_entities(Wall)
	{
		_wall_aabb: = wall_aabb(_wall)

		_moved_aabb: AABB
		_moved_aabb = aabb_move(_aabb, {_movement.x, 0})
		if (collision_aabb_aabb(_moved_aabb, _wall_aabb))
		{
			if (_movement.x < 0)
			{
				_movement.x += _wall_aabb.max.x - _moved_aabb.min.x
			}
			else
			{
				_movement.x += _wall_aabb.min.x - _moved_aabb.max.x
			}
		}

		_moved_aabb = aabb_move(_aabb, {_movement.x, _movement.y})
		if (collision_aabb_aabb(_moved_aabb, _wall_aabb))
		{
			if (_movement.y < 0)
			{
				_movement.y += _wall_aabb.max.y - _moved_aabb.min.y
			}
			else
			{
				_movement.y += _wall_aabb.min.y - _moved_aabb.max.y
			}
		}
	}
	position += _movement


	// Animation
	_is_moving = length_squared(velocity) > 0.001 
	if !is_alive
	{
		animation_player_play(animation_player, resources().agent_animations, "dead")
	}
	else if _is_moving
	{
		animation_player_play(animation_player, resources().agent_animations, "run")
	}
	else
	{
		animation_player_play(animation_player, resources().agent_animations, "idle")
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
		
		x, y : = floor_to_int(position.x), floor_to_int(position.y)

		animation_player_draw(animation_player, Vector2{f32(x), f32(y)} - Vector2{ 8, 16 })
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
		{ x-3, y-6 },
		{ x+3, y },
	}
}

find_closest_agent :: proc(_position: Vector2, _range:f32) -> ^Agent
{
	_agents := get_entities(Agent)
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
