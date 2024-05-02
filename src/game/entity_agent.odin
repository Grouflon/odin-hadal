package game

import "core:fmt"
import "core:math"
import "core:log"
import rl "vendor:raylib"

AgentTeam :: enum
{
	PLAYER,
	ENEMY,
}

Agent :: struct
{
	using entity: Entity,
	
	move_direction: Vector2,
	velocity: Vector2,
	is_alive: bool,
	health_max: i32,
	health: i32,

	is_jumping: bool,
	can_jump: bool,
	jump_length: f32,
	jump_cooldown: f32,
	jump_timer: f32,
	jump_speed: f32,

	animation_player: ^AnimationPlayer,
	collider: ^Collider,
	weapon: ^Weapon,

	team: AgentTeam,

	action_system: ActionSystem,
}

agent_definition :: EntityDefinition(Agent) {

	update = agent_update,
	draw = agent_draw,
	shutdown = agent_shutdown,
}

create_agent :: proc(_position : Vector2, _team: AgentTeam) -> ^Agent
{
	using _agent: = new(Agent)
	entity.type = _agent
	entity.position = _position

	is_alive = true
	health_max = 8
	health = health_max

	weapon = create_weapon(_agent, 3, 3)

	can_jump = true
	is_jumping = false
	jump_length = 20
	jump_speed = 50
	jump_timer = 5
	jump_cooldown = jump_timer

	team = _team

	animation_player = create_animation_player()
	collider = create_collider(
		_agent,
		AABB{
			{-3, -6},
			{ 3,  0},
		},
		team == .PLAYER ? .Agent : .EnemyAgent,
		.Dynamic,
	)

	action_system_initialize(&action_system)

	register_entity(_agent)
	return _agent
}

agent_reset :: proc(_agent: ^Agent)
{
	action_system_clear_actions(&_agent.action_system)
	_agent.move_direction = Vector2{0,0}
	_agent.velocity = Vector2{0,0}
}

agent_shutdown :: proc(using _agent: ^Agent)
{
	free(weapon)
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
	if (is_alive)
	{
		weapon_update(weapon, _dt)
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
	// Draw sprite
	ordered_draw(int(entity.position.y), _agent, proc(_payload: rawptr)
	{
		using agent: = cast(^Agent)_payload
		
		x, y: = floor_to_int(entity.position.x), floor_to_int(entity.position.y)

		animation_player_draw(animation_player, Vector2{f32(x), f32(y)} - Vector2{ 8, 16 })
	})


	weapon_draw(weapon)

	// Draw back UI
	ordered_draw(-1, _agent, proc(_payload: rawptr)
	{
		using agent: = cast(^Agent)_payload

		if (team != .PLAYER) { return }

		path_color: = Color{255, 255, 255, 100}
		pos: = agent.position
		for action in action_system.action_queue
		{
			switch _ in action.payload {
				case ^ActionAgentMoveTo:
				{
					move_to: = action.payload.(^ActionAgentMoveTo)
					draw_dashed_line(pos, move_to.target, path_color, 2.0, game().time * 10)
					rl.DrawEllipseLines(i32(move_to.target.x), i32(move_to.target.y), 4, 2, path_color)
					pos = move_to.target
				}
				case ^ActionAgentJump:
				{
					jump: = action.payload.(^ActionAgentJump)
					rl.DrawLineV(pos,  jump.target, rl.RED)
					pos = jump.target
				}
			}
		}

	})
}


agent_hit_damage :: proc(_agent: ^Agent, _damage: i32)
{
	_agent.health -= _damage

	if (_agent.health <= 0)
	{
		_agent.health = 0
		agent_kill(_agent)
	}
}

agent_kill :: proc(using _agent: ^Agent)
{
	action_system_clear_actions(&action_system)

	is_alive = false
	weapon_stop(weapon)
}


agent_aim :: proc(using _agent: ^Agent, _aim: bool)
{
	weapon_aiming(weapon, _aim)
}

agent_fire :: proc(using _agent: ^Agent, _target: Vector2)
{
	weapon_fire(weapon, _target)
}

agent_aabb :: proc(using _agent: ^Agent) -> AABB
{
	x, y : f32 = math.floor(entity.position.x), math.floor(entity.position.y)
	return AABB {
		{ x-3, y-6 },
		{ x+3, y },
	}
}

agent_is_selectable :: proc(using _agent: ^Agent) -> bool
{
	if (!is_alive) { return false }
	if (team != .PLAYER) { return false }
	
	return true
}

find_closest_agent :: proc(_position: Vector2, _range: f32) -> ^Agent
{
	_agents := get_entities(Agent)
	_closest_agent : ^Agent = nil
	_range_temp := _range
	for _agent in _agents
	{
		if (!_agent.is_alive || _agent.team != .PLAYER ){ continue }

		_dist := distance(_position, _agent.position)

		if (_dist < _range)
		{
			_closest_agent = _agent
			_range_temp = _dist
		}
	}

	return _closest_agent
}
