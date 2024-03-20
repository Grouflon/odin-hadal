package main

ActionProcedure :: proc(_action: ^Action)

ActionManager :: struct
{
	actions: [dynamic]^Action,
}

make_action_manager :: proc() -> ^ActionManager
{
	_manager: = new(ActionManager)
	return _manager
}

delete_action_manager :: proc(_manager: ^ActionManager)
{
	delete(_manager.actions)
	free(_manager)
}

Action :: struct
{
	payload: rawptr,
	manager: ^ActionManager,

	start: ActionProcedure,
	update: ActionProcedure,
	stop: ActionProcedure,
}

action_start :: proc(_payload: rawptr = nil, _start: ActionProcedure = nil, _update: ActionProcedure, _stop: ActionProcedure) -> ^Action
{
	_action := new(Action)
	_action.payload = _payload
	_action.start = _start
	_action.update = _update
	_action.stop = _stop

	_manager := game().action_manager

	append(&_manager.actions, _action)
	_action.manager = _manager

	if _action.start != nil
	{
		_action.start(_action)
	}
	return _action
}

action_stop :: proc(_action: ^Action)
{
	assert(_action != nil)
	assert(action_is_running(_action))

	if _action.stop != nil
	{
		_action.stop(_action)
	}
}

action_is_running :: proc(_action: ^Action) -> bool
{
	assert(_action != nil)
	return _action.manager != nil
}

actions_update :: proc(using _manager: ^ActionManager)
{
	// We go backwards so we can remove actions as we iterate
	for _i := len(actions) - 1; _i >= 0; _i-=1
	{		
		_action: = actions[_i]
		assert(action_is_running(_action))

		if (_action.update != nil)
		{
			_action.update(_action)
		}

		if (!action_is_running(_action))
		{
			unordered_remove(&actions, _i)
			free(_action)
		}
	}
}
