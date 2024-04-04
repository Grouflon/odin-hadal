package game

LAYERS_COUNT :: 32

Layer :: enum
{
	Wall = 0,
	Agent,
	Swarm,
	Hazard,
}

ColliderMobility :: enum
{
	Static,
	Dynamic,
}

Collider :: struct
{
	entity: ^Entity,
	bounds: AABB,
	layer: Layer,
	mobility: ColliderMobility,
	movement: Vector2, // Let's try not using dt in the physics system for now
	overlaps: [dynamic]^Collider,
}

PhysicsManager :: struct
{
	colliders: [dynamic]^Collider,
	colliders_per_layer: [LAYERS_COUNT][dynamic]^Collider,
	layers_response: [LAYERS_COUNT]u64,
}

create_collider :: proc(_entity: ^Entity, _bounds: AABB, _layer: Layer, _mobility: ColliderMobility) -> ^Collider
{
	assert(_entity != nil)

	_collider: = new(Collider)

	_collider.entity = _entity
	_collider.bounds = _bounds
	_collider.layer = _layer
	_collider.mobility = _mobility
	_collider.movement = {0, 0}
	_collider.overlaps = make([dynamic]^Collider)

	physics_manager_register_collider(physics(), _collider)

	return _collider
}

destroy_collider :: proc(_collider: ^Collider)
{
	physics_manager_unregister_collider(physics(), _collider)

	delete(_collider.overlaps)
	free(_collider)
}

physics_manager_initialize :: proc(using _manager: ^PhysicsManager)
{
	colliders = make([dynamic]^Collider)
	for _i in 0..<LAYERS_COUNT
	{
		colliders_per_layer[_i] = make([dynamic]^Collider)
	}
}

physics_manager_shutdown :: proc(using _manager: ^PhysicsManager)
{
	assert(len(colliders) == 0)
	for _i in 0..<LAYERS_COUNT
	{
		delete(colliders_per_layer[_i])
	}
	delete(colliders)
}

physics_manager_register_collider :: proc(using _manager: ^PhysicsManager, _collider: ^Collider)
{
	assert(_manager != nil)
	assert(_collider != nil)
	assert(find(&colliders, _collider) < 0, "Collider already registered")

	append(&colliders, _collider)
	append(&colliders_per_layer[_collider.layer], _collider)
}

physics_manager_unregister_collider :: proc(using _manager: ^PhysicsManager, _collider: ^Collider)
{
	assert(_manager != nil)
	assert(_collider != nil)

	_index: = find(&colliders, _collider)
	assert(_index >= 0, "Collider not registered")
	unordered_remove(&colliders, _index)

	_index = find(&colliders_per_layer[_collider.layer], _collider)
	assert(_index >= 0, "Collider not present in its assigned layer")
	unordered_remove(&colliders_per_layer[_collider.layer], _index)
}

physics_manager_draw_layer :: proc(using _manager: ^PhysicsManager, _layer: Layer, _color: Color)
{
	for _collider in colliders_per_layer[_layer]
	{
		aabb_draw(_collider.entity.position, _collider.bounds, _color)
	}
}