package game

import "core:math/linalg"
import "core:fmt"

ActionAgentJump :: struct
{
	agent: ^Agent,
	target: Vector2,
	reach_threshold: f32,
	previous_position: Vector2,
}

agent_jump_definition :: ActionDefinition {
	start = action_agent_jump_start,
	update = action_agent_jump_update,
	shutdown = action_agent_jump_shutdown,
}

agent_queue_jump :: proc(_agent: ^Agent, _target: Vector2, _reach_threshold: f32 = 0.1)
{
	if (!_agent.is_alive) { return }

	jump: = new(ActionAgentJump)
	jump.agent = _agent
	jump.reach_threshold = _reach_threshold
	action_queue: = _agent.action_system.action_queue
	jump.agent.can_jump = false

	if (len(action_queue) > 0)
	{	last_action: = action_queue[len(action_queue) - 1]
		move_to: = last_action.payload.(^ActionAgentMoveTo)
		jump.previous_position = move_to.target
	}
	else
	{
		jump.previous_position = _agent.position
	}
	
	jump.target = jump.previous_position + normalize(_target - jump.previous_position) * jump.agent.jump_length

	action_system_queue_action(&_agent.action_system, agent_jump_definition, jump)
}

action_agent_jump_start :: proc(_action: ^Action)
{
	jump: = _action.payload.(^ActionAgentJump)
	jump.previous_position = jump.agent.entity.position
	jump.agent.is_jumping = true
}

action_agent_jump_update :: proc(_action: ^Action, _dt: f32)
{
	jump: = _action.payload.(^ActionAgentJump)

	agent_position: = jump.agent.entity.position
	previous_movement: = agent_position - jump.previous_position

	distance_to_target: = length(jump.target - jump.agent.position)
	agent_to_target: = jump.agent.position + normalize(jump.target - agent_position) * jump.agent.jump_speed * _dt

	has_passed_target: = !is_zero(previous_movement) && linalg.dot(previous_movement, agent_to_target) < 0.0 && distance_to_target <= length(jump.agent.velocity) * _dt

	if distance_to_target < jump.reach_threshold || has_passed_target
	{
		jump.agent.entity.position = jump.target
		jump.agent.move_direction = {0, 0}
		action_stop(_action)
		return
	}

	jump.agent.position = agent_to_target
	jump.previous_position = jump.agent.entity.position
}

action_agent_jump_shutdown :: proc(_payload: ActionUnion)
{
	jump: = _payload.(^ActionAgentJump)
	jump.agent.is_jumping = false

	free(jump)
}
