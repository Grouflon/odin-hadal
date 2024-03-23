package main
import rl "vendor:raylib"

Manager :: struct($EntityType: typeid)
{
	type: typeid,

	entities: [dynamic]^EntityType,

	registered: proc(e: ^EntityType),
	unregistered: proc(e: ^EntityType),
	update: proc(e: ^EntityType, dt: f32),
	draw: proc(e: ^EntityType),
	destroy_entity: proc(e: ^EntityType)
}

manager_initialize :: proc($EntityType: typeid, using _manager : ^Manager(EntityType))
{
	entities = make([dynamic]^EntityType)
	type = EntityType
}

manager_shutdown :: proc($EntityType: typeid, using _manager : ^Manager(EntityType))
{
	// Delete all entities that are left in the manager
	if (destroy_entity != nil)
	{
		for _i := len(entities) - 1; _i >= 0; _i-=1 
		{
			_entity: = entities[_i]

			destroy_entity(_entity)
		}
	}

	delete(entities)
}

manager_register_entity :: proc($EntityType: typeid, using _manager : ^Manager(EntityType), _entity : ^EntityType)
{
	assert(_manager != nil)
	assert(_entity != nil)
	assert(find(&entities, _entity) < 0, "Entity already present in the entities list")

	append(&entities, _entity)

	if (registered != nil)
	{
		registered(_entity)
	}
}

manager_unregister_entity :: proc($EntityType: typeid, using _manager : ^Manager(EntityType), _entity : ^EntityType)
{
	assert(_manager != nil)
	assert(_entity != nil)
	index := find(&entities, _entity)
	assert(index >= 0, "Entity not present in the array")

	unordered_remove(&entities, index)

	if (unregistered != nil)
	{
		unregistered(_entity)
	}
}

manager_update :: proc($EntityType: typeid, using _manager : ^Manager(EntityType), _dt: f32)
{
	assert(_manager != nil)
	
	if (update != nil)
	{
		for entity in entities
		{
			update(entity, _dt)
		}
	}
}

manager_draw :: proc($EntityType: typeid, using _manager : ^Manager(EntityType))
{
	assert(_manager != nil)
	
	if (draw != nil)
	{
		for entity in entities
		{
			draw(entity)
		}
	}
}
