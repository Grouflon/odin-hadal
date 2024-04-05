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

CollisionResponse :: enum // this will be encoded on 2 bits, so should never exceed 4 values
{
	None = 0,
	Overlap = 1,
	Collide = 2,
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
	dynamic_colliders: [dynamic]^Collider,
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
	dynamic_colliders = make([dynamic]^Collider)
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
	delete(dynamic_colliders)
	delete(colliders)
}

physics_manager_update :: proc(using _manager: ^PhysicsManager)
{
	for _i in 0..<LAYERS_COUNT
	{
		// Skip layer if total response is 0
		if layers_response[_i] == 0 { continue }

		for _j in _i..<LAYERS_COUNT
		{
			// Find collision response
			_mask: u64 = 3 << u64(_j * 2)
			_response: CollisionResponse = CollisionResponse((layers_response[_i] & _mask) >> u64(_j * 2))

			// Skip layer if response is 0
			if _response == .None { continue }

			for _collider_a in colliders_per_layer[_i]
			{
				_aabb_a: = aabb_move(_collider_a.bounds, _collider_a.entity.position)

				for _collider_b in colliders_per_layer[_j]
				{
					// Early exit if both colliders are static
					if _collider_a.mobility == .Static && _collider_b.mobility == .Static { continue }

					_aabb_b: = aabb_move(_collider_b.bounds, _collider_b.entity.position)

					// First move and resolve along x
					_moved_a: = aabb_move(_aabb_a, {_collider_a.movement.x, 0})
					_moved_b: = aabb_move(_aabb_b, {_collider_b.movement.x, 0})

					if (collision_aabb_aabb(_moved_a, _moved_b))
					{
						_moved_a_center: = aabb_center(_moved_a)
						_moved_b_center: = aabb_center(_moved_b)

						_left_collider: ^Collider
						_left_moved_aabb: AABB
						_right_collider: ^Collider
						_right_moved_aabb: AABB
						if (_moved_a_center.x < _moved_b_center.x)
						{
							_left_collider = _collider_a
							_left_moved_aabb = _moved_a
							_right_collider = _collider_b
							_right_moved_aabb = _moved_b
						}
						else
						{
							_left_collider = _collider_b
							_left_moved_aabb = _moved_b
							_right_collider = _collider_a
							_right_moved_aabb = _moved_a
						}

						_penetration: = _left_moved_aabb.max.x - _right_moved_aabb.min.x
						if (_left_collider.mobility == .Static)
						{
							_right_collider.movement += {_penetration, 0}
						}
						else if (_right_collider.mobility == .Static)
						{
							_left_collider.movement -= {_penetration, 0}
						}
						else // both dynamic
						{
							_half_penetration: = _penetration * 0.5
							_right_collider.movement += {_half_penetration, 0}
							_left_collider.movement -= {_half_penetration, 0}
						}
					}

					// Then move and resolve along y
					_moved_a = aabb_move(_aabb_a, _collider_a.movement)
					_moved_b = aabb_move(_aabb_b, _collider_b.movement)

					if (collision_aabb_aabb(_moved_a, _moved_b))
					{
						_moved_a_center: = aabb_center(_moved_a)
						_moved_b_center: = aabb_center(_moved_b)

						_top_collider: ^Collider
						_top_moved_aabb: AABB
						_bottom_collider: ^Collider
						_bottom_moved_aabb: AABB
						if (_moved_a_center.y < _moved_b_center.y)
						{
							_top_collider = _collider_a
							_top_moved_aabb = _moved_a
							_bottom_collider = _collider_b
							_bottom_moved_aabb = _moved_b
						}
						else
						{
							_top_collider = _collider_b
							_top_moved_aabb = _moved_b
							_bottom_collider = _collider_a
							_bottom_moved_aabb = _moved_a
						}

						_penetration: = _top_moved_aabb.max.y - _bottom_moved_aabb.min.y
						if (_top_collider.mobility == .Static)
						{
							_bottom_collider.movement += {0, _penetration}
						}
						else if (_bottom_collider.mobility == .Static)
						{
							_top_collider.movement -= {0, _penetration}
						}
						else // both dynamic
						{
							_half_penetration: = _penetration * 0.5
							_bottom_collider.movement += {0, _half_penetration}
							_top_collider.movement -= {0, _half_penetration}
						}
					}
				}	
			}
		}
	}

	for _collider in dynamic_colliders
	{
		_collider.entity.position += _collider.movement
		_collider.movement = {0, 0}
	}
}

physics_manager_register_collider :: proc(using _manager: ^PhysicsManager, _collider: ^Collider)
{
	assert(_manager != nil)
	assert(_collider != nil)
	assert(find(&colliders, _collider) < 0, "Collider already registered")

	append(&colliders, _collider)
	if (_collider.mobility == .Dynamic)
	{
		append(&dynamic_colliders, _collider)
	}
	append(&colliders_per_layer[_collider.layer], _collider)
}

physics_manager_unregister_collider :: proc(using _manager: ^PhysicsManager, _collider: ^Collider)
{
	assert(_manager != nil)
	assert(_collider != nil)

	_index: = find(&colliders, _collider)
	assert(_index >= 0, "Collider not registered")
	unordered_remove(&colliders, _index)

	if (_collider.mobility == .Dynamic)
	{
		_index = find(&dynamic_colliders, _collider)
		assert(_index >= 0, "Dynamic Collider not registered")
		unordered_remove(&dynamic_colliders, _index)
	}

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

physics_manager_set_layer_response :: proc(using _manager: ^PhysicsManager, _layer_1: Layer, _layer_2: Layer, _response: CollisionResponse)
{
	_process_response :: proc(_previous_layer_response: u64, _layer_1: Layer, _layer_2: Layer, _response: CollisionResponse) -> u64
	{
		/*
		Ex: 
		   10            response
		01 01 00 01      previous_layer_response
		11 00 11 11 and  additive_mask
		00 10 00 00 or   additive_response

		01 10 00 01      result
		*/
		_additive_mask: = ~(u64(3) << (u64(_layer_2) * 2))
		_additive_response: = u64(_response) << (u64(_layer_2) * 2)
		return (_previous_layer_response & _additive_mask) | _additive_response
	}
	
	layers_response[_layer_1] = _process_response(layers_response[_layer_1], _layer_1, _layer_2, _response)
	layers_response[_layer_2] = _process_response(layers_response[_layer_2], _layer_2, _layer_1, _response)
}
