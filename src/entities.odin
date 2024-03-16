package main

import rl "vendor:raylib"

Entity :: struct
{
	position : rl.Vector2,
	priority : i32,

	added : proc(e : ^Entity),
	removed : proc(e : ^Entity),
	update : proc(e : ^Entity),
	draw : proc(e : ^Entity),
}

EntityManager :: struct
{
	entities : [dynamic]^Entity
}

update_entities :: proc(using _manager : ^EntityManager)
{
	for entity in entities
	{
		if (entity.update != nil)
		{
			entity.update(entity)
		}
	}
}

draw_entities :: proc(using _manager : ^EntityManager)
{
	for entity in entities
	{
		if (entity.draw != nil)
		{
			entity.draw(entity)
		}
	}
}

add_entity :: proc(using _manager : ^EntityManager, _entity : ^Entity)
{
	assert(_entity != nil)
	assert(find(&entities, _entity) < 0, "Entity already present in the entities list")

	append(&entities, _entity)

	if (_entity.added != nil)
	{
		_entity.added(_entity)
	}
}

remove_entity :: proc(using manager : ^EntityManager, _entity : ^Entity)
{
	assert(_entity != nil)
	index := find(&entities, _entity)
	assert(index >= 0, "Entity not present in the array")

	unordered_remove(&entities, index)

	if (_entity.removed != nil)
	{
		_entity.removed(_entity)
	}
}
