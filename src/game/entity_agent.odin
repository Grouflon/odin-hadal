package game

import "core:fmt"
import "core:math"
import "core:log"
import rl "vendor:raylib"

Agent :: struct
{
	using entity: Entity,
	
	move_direction: Vector2,
	velocity: Vector2,
	is_alive: bool,

	is_jumping: bool,
	can_jump: bool,
	jump_length: f32,
	jump_cooldown: f32,
	jump_timer: f32,
	jump_speed: f32,

	is_search_target: bool,

	can_aim: bool,
	is_aiming: bool,
	aim_target: Vector2,
	aim_cooldown: f32,
	aim_timer: f32,

	is_firing: bool,
	fire_cooldown: f32,
	fire_timer: f32,

	is_reloading: bool,
	reload_cooldown: f32,
	reload_timer: f32,
	
	animation_player: ^AnimationPlayer,
	collider: ^Collider,

	action_system: ActionSystem,
}

agent_definition :: EntityDefinition(Agent) {

	update = agent_update,
	draw = agent_draw,
	shutdown = agent_shutdown,
}

create_agent :: proc(_position : Vector2) -> ^Agent
{
	using _agent: = new(Agent)
	entity.type = _agent
	entity.position = _position

	is_alive = true

	can_aim = true
	aim_timer = 3
	aim_cooldown = aim_timer

	reload_timer = 3
	reload_cooldown = reload_timer

	can_jump = true
	is_jumping = false
	jump_length = 20
	jump_speed = 50
	jump_timer = 5
	jump_cooldown = jump_timer

	animation_player = create_animation_player()
	collider = create_collider(
		_agent,
		AABB{
			{-3, -6},
			{ 3,  0},
		},
		.Agent,
		.Dynamic,
	)

	action_system_initialize(&action_system)

	register_entity(_agent)
	return _agent
}

agent_shutdown :: proc(using _agent: ^Agent)
{
	action_system_shutdown(&action_system)
	destroy_collider(collider)
	destroy_animation_player(animation_player)
}

agent_update :: proc(using _agent: ^Agent, _dt: f32)
{	
	using rl
	_is_moving: = false

	// Actions
	action_system_update(&action_system, _dt)

	// Velocity
	_velocity_length: = length(velocity)
	_direction: Vector2

	_deceleration_multiplier: f32 = 1.0
	_ices: = get_entities(Ice)
	for _ice in _ices
	{
		if (collision_aabb_aabb(agent_aabb(_agent), ice_aabb(_ice)))
		{
			_deceleration_multiplier = 0.1
			break
		}
	}

	// aim
	{
		if (is_reloading)
		{
			is_reloading = cooldown_timer(is_reloading, &reload_cooldown, reload_timer, _dt)
			can_aim = true
		}

		if (is_alive && IsKeyDown(KeyboardKey.A) && can_aim)
		{
			is_search_target = true
			aim_target = game().mouse.world_position
		} else if (is_search_target) {
			is_search_target = false
		}
	}

	// jump
	{
		if (!can_jump)
		{
			can_jump = cooldown_timer(!can_jump, &jump_cooldown, jump_timer, _dt)
		}

		if (is_jumping)
		{
			return
		}
	}

	if (is_alive && !is_zero(move_direction))
	{
		_direction = normalize(move_direction)
		_velocity_length += game_settings.agent_acceleration * _dt
		_velocity_length = math.min(_velocity_length, game_settings.agent_max_speed)
	}
	else
	{
		_direction = normalize(velocity)
		_velocity_length -= game_settings.agent_deceleration * _deceleration_multiplier * _dt
		_velocity_length = math.max(_velocity_length, 0)
	}
	velocity = _direction * _velocity_length

	// Movement
	entity.position += velocity * _dt

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

agent_draw :: proc(using _agent: ^Agent)
{
	ordered_draw(int(entity.position.y), _agent, proc(_payload: rawptr)
	{
		using agent: = cast(^Agent)_payload
		
		x, y: = floor_to_int(entity.position.x), floor_to_int(entity.position.y)

		animation_player_draw(animation_player, Vector2{f32(x), f32(y)} - Vector2{ 8, 16 })

		// jump
		xx: = rl.Vector2Rotate({1, 0}, 0)
		yy: = rl.Vector2Rotate({0, 1}, 0)
		

		if (is_search_target || is_aiming)
		{
			//direction
			angle: f32 = 10 * rl.DEG2RAD
			aim_direction: = aim_target - agent.position
			babord: = rl.Vector2Rotate(aim_direction, -angle/2)
			tribord: = rl.Vector2Rotate(aim_direction, angle/2)

			rl.DrawLineV(agent.position, agent.position + babord * 500, rl.PINK)
			rl.DrawLineV(agent.position, agent.position + tribord * 500, rl.PINK)
		}
		reload_color: = is_reloading || is_aiming ? rl.RED : rl.GREEN
		reload_position: = agent.position + Vector2{-5, 0}
		rl.DrawLineV(reload_position, reload_position + Vector2{0, -1} * 5, reload_color)

		pos: = agent.position
		for action in action_system.action_queue
		{
			move_to: = cast(^ActionAgentMoveTo)action.payload
			rl.DrawLineV(pos,  move_to.target, reload_color)
			pos = move_to.target
		}

	})
}

agent_kill :: proc(using _agent: ^Agent)
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

	action_system_clear_actions(&action_system)

	is_alive = false
}

agent_aabb :: proc(using _agent: ^Agent) -> AABB
{
	x, y : f32 = math.floor(entity.position.x), math.floor(entity.position.y)
	return AABB {
		{ x-3, y-6 },
		{ x+3, y },
	}
}

find_closest_agent :: proc(_position: Vector2, _range: f32) -> ^Agent
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
