package game

ActionSystem :: struct
{
	action_queue: [dynamic]^Action,
}

ActionDefinition :: struct
{
	start: proc(_action: ^Action),
	update: proc(_action: ^Action, _dt: f32),
	stop: proc(_action: ^Action),
	shutdown: proc(_payload: ActionUnion),
}

ActionState :: enum
{
	Queued,
	Running,
	Stopped,
}

ActionUnion :: union{
	^ActionAgentMoveTo,
	^ActionAgentJump,
}

Action :: struct
{
	definition: ActionDefinition,
	state: ActionState,
	payload: ActionUnion,
	system: ^ActionSystem,
}

action_system_initialize :: proc(using _system: ^ActionSystem)
{
	assert(_system != nil)

	_system.action_queue = make([dynamic]^Action)
}

action_system_shutdown :: proc(using _system: ^ActionSystem)
{
	assert(_system != nil)

	action_system_clear_actions(_system)
	delete(_system.action_queue)
}

action_system_queue_action :: proc(using _system: ^ActionSystem, _definition: ActionDefinition, _payload: ActionUnion = nil) -> ^Action
{
	assert(_system != nil)

	action: = new(Action)
	action.definition = _definition
	action.payload = _payload
	action.system = _system
	action.state = .Queued

	append(&action_queue, action)

	return action
}

action_system_clear_actions :: proc(using _system: ^ActionSystem)
{
	assert(_system != nil)

	for i: = 0; i < len(action_queue); i += 1
	{
		action: = action_queue[i]
		if (action.state == .Running)
		{
			action_stop(action)
		}

		action_shutdown(action)
		free(action)
	}
	clear(&action_queue)
}

action_system_dequeue_actions :: proc(using _system: ^ActionSystem)
{
	assert(_system != nil)

	for len(action_queue) > 0 && action_queue[0].state != .Running
	{
		action: ^Action = action_queue[0]
		if (action.state == .Queued)
		{
			action_start(action)
		}

		if (action.state == .Stopped)
		{
			action_shutdown(action)
			ordered_remove(&action_queue, 0)
			free(action)
		}
	}
}

action_system_update :: proc(using _system: ^ActionSystem, _dt: f32)
{
	assert(_system != nil)

	action_system_dequeue_actions(_system)

	if (len(action_queue) > 0)
	{
		assert(action_queue[0].state == .Running)
		action_update(action_queue[0], _dt)
	}

	action_system_dequeue_actions(_system)
}

action_system_last_action_position :: proc(using _system: ^ActionSystem) -> Vector2
{
	if (len(action_queue) > 0)
	{
		last_action: = action_queue[len(action_queue) - 1]
		switch _ in last_action.payload {
			case ^ActionAgentMoveTo:
			{
				move_to: = last_action.payload.(^ActionAgentMoveTo)
				return  move_to.target
			}
			case ^ActionAgentJump:
			{
				jump: = last_action.payload.(^ActionAgentJump)
				return jump.target
			}
		}
	}

	return Vector2{0,0}
}

action_start :: proc(using _action: ^Action)
{
	assert(_action != nil)
	assert(_action.state == .Queued)

	_action.state = .Running
	if (_action.definition.start != nil)
	{
		_action.definition.start(_action)
	}
}

action_update :: proc(using _action: ^Action, _dt: f32)
{
	assert(_action != nil)
	assert(_action.state == .Running)

	if (_action.definition.update != nil)
	{
		_action.definition.update(_action, _dt)
	}
}

action_stop :: proc(using _action: ^Action)
{
	assert(_action != nil)
	assert(_action.state == .Running)

	if (_action.definition.stop != nil)
	{
		_action.definition.stop(_action)
	}
	_action.state = .Stopped
}

action_shutdown :: proc(using _action: ^Action)
{
	assert(_action != nil)
	assert(_action.state != .Running)

	if (_action.definition.shutdown != nil)
	{
		_action.definition.shutdown(_action.payload)
	}
}

