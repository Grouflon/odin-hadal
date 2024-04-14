package game

LAYERS_COUNT :: 32

Layer :: enum
{
	Wall = 0,
	Agent,
	Swarm,
	Hazard,
	EnemyBullet,
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
	collisions: [dynamic]^Collider,
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
	_collider.overlaps = make([dynamic]^Collider)
	_collider.collisions = make([dynamic]^Collider)

	physics_manager_register_collider(physics(), _collider)

	return _collider
}

destroy_collider :: proc(_collider: ^Collider)
{
	physics_manager_unregister_collider(physics(), _collider)

	delete(_collider.collisions)
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
	// Clear previous frame results
	for _collider in colliders
	{
		clear(&_collider.collisions)
		clear(&_collider.overlaps)
	}

	// Iterate through every pair
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
				for _collider_b in colliders_per_layer[_j]
				{
					if (_collider_a == _collider_b) { continue }

					if (_response == .Collide)
					{
						solve_collision(_collider_a, _collider_b)
					}
					else if (_response == .Overlap)
					{
						solve_overlap(_collider_a, _collider_b)
					}
				}	
			}
		}
	}
}

solve_collision :: proc(_collider_a: ^Collider, _collider_b: ^Collider)
{
	if (_collider_a.mobility == .Static && _collider_b.mobility == .Static) { return }

	_a: = aabb_move(_collider_a.bounds, _collider_a.entity.position)
	_b: = aabb_move(_collider_b.bounds, _collider_b.entity.position)

	compute_push :: proc(_a: AABB, _b: AABB) -> Vector2
	{
		_a_center: = aabb_center(_a)
		_b_center: = aabb_center(_b)
		_bary_0: = _b_center
		_bary_1: = _b.max
		_bary_2: = Vector2{_b.max.x, _b.min.y}

		_bary_coords: = barycentric_coordinates(_a_center, _bary_0, _bary_1, _bary_2)

		_push: Vector2
		if (_bary_coords.y > 0 && _bary_coords.z > 0) // push right
		{
			_push = { _b.max.x - _a.min.x, 0.0 }
		}
		else if (_bary_coords.y > 0 && _bary_coords.z <= 0) // push down
		{
			_push = { 0.0,  _b.max.y - _a.min.y }
		}
		else if (_bary_coords.y <= 0 && _bary_coords.z <= 0) // push left
		{
			_push = {_b.min.x - _a.max.x,  0.0 } // push up
		}
		else if (_bary_coords.y <= 0 && _bary_coords.z > 0)
		{
			_push = { 0.0, _b.min.y - _a.max.y }
		}

		return _push
	}

	if (collision_aabb_aabb(_a, _b))
	{
		append_unique(&_collider_a.collisions, _collider_b)
		append_unique(&_collider_b.collisions, _collider_a)

		if (_collider_a.mobility == .Static)
		{
			_b_push: = compute_push(_b, _a)
			_collider_b.entity.position += _b_push
		}
		else if (_collider_b.mobility == .Static)
		{
			_a_push: = compute_push(_a, _b)
			_collider_a.entity.position += _a_push
		}
		else
		{
			_a_push: = compute_push(_a, _b)
			_b_push: = compute_push(_b, _a)

			_collider_a.entity.position += _a_push * 0.5
			_collider_b.entity.position += _b_push * 0.5
		}
	}
}

solve_overlap :: proc(_collider_a: ^Collider, _collider_b: ^Collider)
{
	_a: = aabb_move(_collider_a.bounds, _collider_a.entity.position)
	_b: = aabb_move(_collider_b.bounds, _collider_b.entity.position)
	
	if (collision_aabb_aabb(_a, _b))
	{
		append_unique(&_collider_a.overlaps, _collider_b)
		append_unique(&_collider_b.overlaps, _collider_a)
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

physics_manager_get_colliders :: proc(using _manager: ^PhysicsManager, _layer: Layer) -> [dynamic]^Collider
{
	return colliders_per_layer[_layer]
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

// Shorthands
get_colliders :: proc(_layer: Layer) -> [dynamic]^Collider
{
	return physics_manager_get_colliders(&game().physics_manager, _layer)
}