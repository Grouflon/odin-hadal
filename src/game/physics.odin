package game

LAYERS_COUNT :: 32

Layer :: enum
{
	Wall = 0,
	Agent,
	Swarm,
	Hazard,
	Turret,
	EnemyBullet,
	AllyBullet,
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

RaycastResult :: struct
{
	collider: ^Collider,
	hit_point: Vector2,
}

Ray2d :: struct
{
	origin: Vector2,
	direction: Vector2,
	length: f32
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

	collider: = new(Collider)

	collider.entity = _entity
	collider.bounds = _bounds
	collider.layer = _layer
	collider.mobility = _mobility
	collider.overlaps = make([dynamic]^Collider)
	collider.collisions = make([dynamic]^Collider)

	physics_manager_register_collider(physics(), collider)

	return collider
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
	for collider in colliders
	{
		clear(&collider.collisions)
		clear(&collider.overlaps)
	}

	// Iterate through every pair
	for i in 0..<LAYERS_COUNT
	{
		// Skip layer if total response is 0
		if layers_response[i] == 0 { continue }

		for j in i..<LAYERS_COUNT
		{
			// Find collision response
			mask: u64 = 3 << u64(j * 2)
			response: CollisionResponse = CollisionResponse((layers_response[i] & mask) >> u64(j * 2))

			// Skip layer if response is 0
			if response == .None { continue }

			for collider_a in colliders_per_layer[i]
			{
				for collider_b in colliders_per_layer[j]
				{
					if (collider_a == collider_b) { continue }

					if (response == .Collide)
					{
						solve_collision(collider_a, collider_b)
					}
					else if (response == .Overlap)
					{
						solve_overlap(collider_a, collider_b)
					}
				}	
			}
		}
	}
}

solve_collision :: proc(_collider_a: ^Collider, _collider_b: ^Collider)
{
	if (_collider_a.mobility == .Static && _collider_b.mobility == .Static) { return }

	aabb_a: = aabb_move(_collider_a.bounds, _collider_a.entity.position)
	aabb_b: = aabb_move(_collider_b.bounds, _collider_b.entity.position)

	compute_push :: proc(_aabb_a: AABB, _aabb_b: AABB) -> Vector2
	{
		a_center: = aabb_center(_aabb_a)
		b_center: = aabb_center(_aabb_b)
		bary_0: = b_center
		bary_1: = _aabb_b.max
		bary_2: = Vector2{_aabb_b.max.x, _aabb_b.min.y}

		bary_coords: = barycentric_coordinates(a_center, bary_0, bary_1, bary_2)

		push: Vector2
		if (bary_coords.y > 0 && bary_coords.z > 0) // push right
		{
			push = { _aabb_b.max.x - _aabb_a.min.x, 0.0 }
		}
		else if (bary_coords.y > 0 && bary_coords.z <= 0) // push down
		{
			push = { 0.0,  _aabb_b.max.y - _aabb_a.min.y }
		}
		else if (bary_coords.y <= 0 && bary_coords.z <= 0) // push left
		{
			push = {_aabb_b.min.x - _aabb_a.max.x,  0.0 } // push up
		}
		else if (bary_coords.y <= 0 && bary_coords.z > 0)
		{
			push = { 0.0, _aabb_b.min.y - _aabb_a.max.y }
		}

		return push
	}

	if (collision_aabb_aabb(aabb_a, aabb_b))
	{
		append_unique(&_collider_a.collisions, _collider_b)
		append_unique(&_collider_b.collisions, _collider_a)

		if (_collider_a.mobility == .Static)
		{
			b_push: = compute_push(aabb_b, aabb_a)
			_collider_b.entity.position += b_push
		}
		else if (_collider_b.mobility == .Static)
		{
			a_push: = compute_push(aabb_a, aabb_b)
			_collider_a.entity.position += a_push
		}
		else
		{
			a_push: = compute_push(aabb_a, aabb_b)
			b_push: = compute_push(aabb_b, aabb_a)

			_collider_a.entity.position += a_push * 0.5
			_collider_b.entity.position += b_push * 0.5
		}
	}
}

solve_overlap :: proc(_collider_a: ^Collider, _collider_b: ^Collider)
{
	aabb_a: = aabb_move(_collider_a.bounds, _collider_a.entity.position)
	aabb_b: = aabb_move(_collider_b.bounds, _collider_b.entity.position)
	
	if (collision_aabb_aabb(aabb_a, aabb_b))
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

	index: = find(&colliders, _collider)
	assert(index >= 0, "Collider not registered")
	unordered_remove(&colliders, index)

	if (_collider.mobility == .Dynamic)
	{
		index = find(&dynamic_colliders, _collider)
		assert(index >= 0, "Dynamic Collider not registered")
		unordered_remove(&dynamic_colliders, index)
	}

	index = find(&colliders_per_layer[_collider.layer], _collider)
	assert(index >= 0, "Collider not present in its assigned layer")
	unordered_remove(&colliders_per_layer[_collider.layer], index)
}

physics_manager_draw_layer :: proc(using _manager: ^PhysicsManager, _layer: Layer, _color: Color)
{
	for collider in colliders_per_layer[_layer]
	{
		aabb_draw(collider.entity.position, collider.bounds, _color)
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
		additive_mask: = ~(u64(3) << (u64(_layer_2) * 2))
		additive_response: = u64(_response) << (u64(_layer_2) * 2)
		return (_previous_layer_response & additive_mask) | additive_response
	}
	
	layers_response[_layer_1] = _process_response(layers_response[_layer_1], _layer_1, _layer_2, _response)
	layers_response[_layer_2] = _process_response(layers_response[_layer_2], _layer_2, _layer_1, _response)
}

physics_manager_raycast :: proc(using _manager: ^PhysicsManager, _layer: Layer, _position: Vector2, _direction: Vector2, _length: f32, _cast_results: ^[dynamic]RaycastResult = nil) -> bool
{
	has_collided: = false
	layer_colliders: = colliders_per_layer[_layer]

	ray: Ray2d = {origin = _position, direction = _direction, length = _length}
	hit_point: Vector2

	for collider in layer_colliders
	{
		bounds: AABB = aabb_move(collider.bounds, collider.entity.position)

		if (collision_raycast2d_aabb(ray, bounds, &hit_point))
		{
			current_hit_distance_squared: = distance_squared(_position, hit_point)
			index: = 0

			for raycast_result in _cast_results
			{
				hit_distance_squared: = distance_squared(_position, raycast_result.hit_point)
				if (hit_distance_squared > current_hit_distance_squared)
				{
					break
				}
				index += 1
			}
			if (_cast_results != nil)
			{
				inject_at(_cast_results, index, RaycastResult{collider=collider, hit_point=hit_point})
			}
			has_collided = true
		}
	}

	return has_collided
}

physics_manager_pointcast :: proc(using _manager: ^PhysicsManager, _layer: Layer, _point: Vector2, _cast_results: ^[dynamic]^Collider = nil) -> bool
{
	has_collided: = false
	layer_colliders: = colliders_per_layer[_layer]

	for collider in layer_colliders
	{
		bounds: AABB = aabb_move(collider.bounds, collider.entity.position)

		if (collision_aabb_point(bounds, _point))
		{
			if (_cast_results != nil)
			{
				append(_cast_results, collider)
			} 
			has_collided = true
		}
	}

	return has_collided
}


physics_raycast :: proc(_layer: Layer, _position: Vector2, _direction: Vector2, _length: f32, _cast_results: ^[dynamic]RaycastResult = nil) -> bool
{
	return physics_manager_raycast(&game().physics_manager, _layer, _position, _direction, _length, _cast_results)
}

physics_pointcast :: proc(_layer: Layer, _point: Vector2, _cast_results: ^[dynamic]^Collider = nil) -> bool
{
	return physics_manager_pointcast(&game().physics_manager, _layer, _point, _cast_results)
}
