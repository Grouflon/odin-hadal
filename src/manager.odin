package main
import rl "vendor:raylib"

manager_register_entity :: proc(_manager : ^$M, _entity : ^$E)
{
	assert(_manager != nil)
	assert(_entity != nil)
	assert(find(&_manager.entities, _entity) < 0, "Entity already present in the entities list")

	append(&_manager.entities, _entity)

	if (_manager.registered != nil)
	{
		_manager.registered(_entity)
	}
}

manager_unregister_entity :: proc(_manager : ^$M, _entity : ^$E)
{
	assert(_manager != nil)
	assert(_entity != nil)
	index := find(&_manager.entities, _entity)
	assert(index >= 0, "Entity not present in the array")

	unordered_remove(&_manager.entities, index)

	if (_manager.unregistered != nil)
	{
		_manager.unregistered(_entity)
	}
}

manager_update :: proc(_manager : ^$M)
{
	assert(_manager != nil)
	dt:=rl.GetFrameTime()
	
	if (_manager.update != nil)
	{
		for entity in _manager.entities
		{
			_manager.update(entity, dt)
		}
	}
}