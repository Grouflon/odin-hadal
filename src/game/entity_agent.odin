package game

import "core:fmt"
import "core:math"
import "core:log"
import rl "vendor:raylib"

Agent :: struct
{
	position: Vector2,
	velocity : Vector2,
	friction : f32,
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
	friction = 1

	register_entity(_agent)
	return _agent
}

agent_shutdown :: proc(using _agent: ^Agent)
{
	destroy_animation_player(animation_player)
}

agent_update :: proc(using _agent : ^Agent, _dt: f32)
{
	is_moving: = false
	if (is_alive && game().mouse.down[1])
	{
		wp:= game().mouse.world_position
		velocity = normalize(wp - position) * game_settings.agent_speed
		position += velocity * _dt
		is_moving = true 
	}
	else if (friction != 1)
	{
		if (length(velocity) > 0)
		{
			velocity = velocity * TimeIndependentLerp2(1, 0, 0.2, _dt)
			position += velocity
			is_moving = true
		}
	}

	if !is_alive
	{
		animation_player_play(animation_player, resources().agent_animations, "dead")
	}
	else if is_moving
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
		{ x, y-1 },
		{ x+1, y+1 },
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
