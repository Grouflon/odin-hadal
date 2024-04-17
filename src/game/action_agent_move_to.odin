package game

import "core:math/linalg"

ActionAgentMoveTo :: struct
{
	agent: ^Agent,
	target: Vector2,
	reach_threshold: f32,
	previous_position: Vector2,
}

agent_move_to_definition :: ActionDefinition {
	start = action_agent_move_to_start,
	update = action_agent_move_to_update,
	shutdown = action_agent_move_to_shutdown,
}

agent_queue_move_to :: proc(_agent: ^Agent, _target: Vector2, _reach_threshold: f32 = 0.1)
{
	if (!_agent.is_alive) { return }

	move_to: = new(ActionAgentMoveTo)
	move_to.agent = _agent
	move_to.target = _target
	move_to.reach_threshold = _reach_threshold

	action_system_queue_action(&_agent.action_system, agent_move_to_definition, move_to)
}

action_agent_move_to_start :: proc(_action: ^Action)
{
	move_to: = cast(^ActionAgentMoveTo)_action.payload

	move_to.previous_position = move_to.agent.entity.position
}

action_agent_move_to_update :: proc(_action: ^Action, _dt: f32)
{
	move_to: = cast(^ActionAgentMoveTo)_action.payload

	agent_position: = move_to.agent.entity.position
	previous_movement: = agent_position - move_to.previous_position
	agent_to_target: = move_to.target - agent_position
	distance_to_target: = length(agent_to_target)

	has_passed_target: = !is_zero(previous_movement) && linalg.dot(previous_movement, agent_to_target) < 0.0 && distance_to_target <= length(move_to.agent.velocity) * _dt

	if distance_to_target < move_to.reach_threshold || has_passed_target
	{
		move_to.agent.entity.position = move_to.target
		move_to.agent.move_direction = {0, 0}
		action_stop(_action)
		return
	}

	move_to.agent.move_direction = agent_to_target
	move_to.previous_position = move_to.agent.entity.position
}

action_agent_move_to_shutdown :: proc(_payload: rawptr)
{
	move_to: = cast(^ActionAgentMoveTo)_payload
	free(move_to)
}
