package game

import "core:math/linalg"
import "core:fmt"

ActionAgentFire :: struct
{
	agent: ^Agent,
	target: Vector2,
	reach_threshold: f32,
}

agent_fire_definition :: ActionDefinition {
	start = action_agent_fire_start,
	update = action_agent_fire_update,
	shutdown = action_agent_fire_shutdown,
}

agent_queue_fire :: proc(_agent: ^Agent, _target: Vector2, _reach_threshold: f32 = 0.1)
{
	if (!_agent.is_alive) { return }

	fire: = new(ActionAgentFire)
	fire.agent = _agent
	fire.reach_threshold = _reach_threshold
	fire.target = _target
	fire.agent.can_aim = false

	action_system_queue_action(&_agent.action_system, agent_fire_definition, fire)
}

action_agent_fire_start :: proc(_action: ^Action)
{
	fire: = _action.payload.(^ActionAgentFire)
	fire.agent.is_aiming = true
}

action_agent_fire_update :: proc(_action: ^Action, _dt: f32)
{
	fire: = _action.payload.(^ActionAgentFire)

	if (cooldown_timer(fire.agent.is_aiming, &fire.agent.aim_cooldown, fire.agent.aim_timer, _dt))
	{
		dir: = normalize(fire.target - fire.agent.position)
		create_bullet_fire(fire.agent.position + dir * 10, dir * 50, fire.agent, .AllyBullet)
		action_stop(_action)
		return
	}
}

action_agent_fire_shutdown :: proc(_payload: ActionUnion)
{
	fire: = _payload.(^ActionAgentFire)
	fire.agent.is_aiming = false
	fire.agent.is_reloading = true

	free(fire)
}
