package game

import "core:reflect"
import "core:runtime"

EntityDefinition :: struct($Type: typeid)
{
	registered: proc(e: ^Type),
	unregistered: proc(e: ^Type),
	update: proc(e: ^Type, dt: f32),
	draw: proc(e: ^Type),
	shutdown: proc(e: ^Type),
}

EntityTypeBase :: struct
{
	type: typeid,

	shutdown_type: proc(_type: ^EntityTypeBase),
	clear_entities: proc(_type: ^EntityTypeBase),

	register: proc(_type: ^EntityTypeBase, _e: ^Entity),
	unregister: proc(_type: ^EntityTypeBase, _e: ^Entity),
	update: proc(_type: ^EntityTypeBase, _dt: f32),
	draw: proc(_type: ^EntityTypeBase),
	shutdown: proc(_type: ^EntityTypeBase, _e: ^Entity),
}

EntityType :: struct($Type: typeid)
{
	using base: EntityTypeBase,

	definition: EntityDefinition(Type),
	entities: [dynamic]^Type,
}

EntityManager :: struct
{
	types: [dynamic]^EntityTypeBase,
	types_map: map[typeid]^EntityTypeBase,
}

entity_manager_initialize :: proc(using _manager: ^EntityManager)
{
	types = make([dynamic]^EntityTypeBase)
	types_map = make(map[typeid]^EntityTypeBase)
}

entity_manager_clear_entities :: proc(using _manager: ^EntityManager)
{
	for _type in types
	{
		_type.clear_entities(_type)
	}
}

entity_manager_shutdown :: proc(using _manager: ^EntityManager)
{
	for _type in types
	{
		_type.shutdown_type(_type)
		free(_type)
	}

	delete(types_map)
	delete(types)
}

get_entity_typeid :: proc(_entity: ^Entity) -> typeid
{
	_pointer_type_info: = reflect.union_variant_type_info(_entity.type)
	return _pointer_type_info.variant.(runtime.Type_Info_Pointer).elem.id
}

entity_manager_register_entity :: proc(using _manager: ^EntityManager, _entity: ^Entity)
{
	_type: = get_entity_typeid(_entity)
	_entity_type: = types_map[_type]
	assert(_entity_type != nil, "Unregistered entity type")

	_entity_type.register(_entity_type, _entity)
}

entity_manager_unregister_entity :: proc(using _manager: ^EntityManager, _entity: ^Entity)
{
	_type: = get_entity_typeid(_entity)
	_entity_type: = types_map[_type]
	assert(_entity_type != nil, "Unregistered entity type")

	_entity_type.unregister(_entity_type, _entity)
}

entity_manager_update :: proc(using _manager: ^EntityManager, _dt: f32)
{
	for _type in types
	{
		_type.update(_type, _dt)
	}
}

entity_manager_draw :: proc(using _manager: ^EntityManager)
{
	for _type in types
	{
		_type.draw(_type)
	}
}

entity_manager_shutdown_entity :: proc(using _manager: ^EntityManager, _entity: ^Entity)
{
	_type: = get_entity_typeid(_entity)
	_entity_type: = types_map[_type]
	assert(_entity_type != nil, "Unregistered entity type")

	_entity_type.shutdown(_entity_type, _entity)
}

entity_manager_destroy_entity :: proc(using _manager: ^EntityManager, _entity: ^Entity)
{
	entity_manager_unregister_entity(_manager, _entity)
	entity_manager_shutdown_entity(_manager, _entity)
	free(_entity)
}

entity_manager_register_type :: proc(using _manager: ^EntityManager, $Type: typeid, _definition: EntityDefinition(Type))
{
	assert(_manager != nil)

	_entity_type: = new(EntityType(Type))
	_entity_type.type = Type
	_entity_type.definition = _definition
	_entity_type.entities = make([dynamic]^Type)

	_entity_type.shutdown_type = proc(_type: ^EntityTypeBase)
	{
		_true_type: = cast(^EntityType(Type))_type
		delete(_true_type.entities)
	}

	_entity_type.clear_entities = proc(_type: ^EntityTypeBase)
	{
		_true_type: = cast(^EntityType(Type))_type
		for _entity in _true_type.entities
		{
			_type.shutdown(_type, _entity)
			free(_entity)
		}
		clear(&_true_type.entities)
	}

	_entity_type.register = proc(_type: ^EntityTypeBase, _e: ^Entity)
	{
		_true_type: = cast(^EntityType(Type))_type
		_entity: = _e.type.(^Type)

		assert(_entity != nil)
		assert(find(&_true_type.entities, _entity) < 0, "Entity already present in the entities list")

		append(&_true_type.entities, _entity)
		if _true_type.definition.registered != nil
		{
			_true_type.definition.registered(_entity)
		}
	}

	_entity_type.unregister = proc(_type: ^EntityTypeBase, _e: ^Entity)
	{
		_true_type: = cast(^EntityType(Type))_type
		_entity: = _e.type.(^Type)

		assert(_entity != nil)
		_index := find(&_true_type.entities, _entity)
		assert(_index >= 0, "Entity not present in the array")

		unordered_remove(&_true_type.entities, _index)

		if _true_type.definition.unregistered != nil
		{
			_true_type.definition.unregistered(_entity)
		}
	}

	_entity_type.update = proc(_type: ^EntityTypeBase, _dt: f32)
	{
		_true_type: = cast(^EntityType(Type))_type
		if _true_type.definition.update != nil
		{
			for _entity in _true_type.entities
			{
				_true_type.definition.update(_entity, _dt)
			}
		}
	}

	_entity_type.draw = proc(_type: ^EntityTypeBase)
	{
		_true_type: = cast(^EntityType(Type))_type
		if _true_type.definition.draw != nil
		{
			for _entity in _true_type.entities
			{
				_true_type.definition.draw(_entity)
			}
		}
	}

	_entity_type.shutdown = proc(_type: ^EntityTypeBase, _e: ^Entity)
	{
		_true_type: = cast(^EntityType(Type))_type
		_entity: = _e.type.(^Type)
		if _true_type.definition.shutdown != nil
		{
			_true_type.definition.shutdown(_entity)
		}
	}

	append(&types, _entity_type)
	types_map[Type] = _entity_type
}

entity_manager_get_entities :: proc(using _manager: ^EntityManager, $Type: typeid) -> []^Type
{
	_type: = typeid_of(Type)
	_entity_type: = types_map[_type]
	assert(_entity_type != nil, "Unregistered entity type")
	_true_type: = cast(^EntityType(Type))_entity_type

	return _true_type.entities[:]
}

// Shorthands
register_entity :: proc(_entity: ^Entity)
{
	entity_manager_register_entity(&game().entity_manager, _entity)
}

unregister_entity :: proc(_entity: ^Entity)
{
	entity_manager_unregister_entity(&game().entity_manager, _entity)
}

destroy_entity :: proc(_entity: ^Entity)
{
	entity_manager_destroy_entity(&game().entity_manager, _entity)
}

get_entities :: proc($Type: typeid) -> []^Type
{
	return entity_manager_get_entities(&game().entity_manager, Type)
}