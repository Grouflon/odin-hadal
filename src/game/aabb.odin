package game

import rl "vendor:raylib"

AABB :: struct
{
	min: Vector2,
	max: Vector2
}

aabb_move :: proc(_aabb: AABB, _offset: Vector2) -> AABB
{
	return AABB {
		_aabb.min + _offset,
		_aabb.max + _offset,
	}
}

aabb_center :: proc(_aabb: AABB) -> Vector2
{
	return _aabb.min + (_aabb.max - _aabb.min) * 0.5
}

// aabb_resolve_static_collision :: proc(_moving_aabb: AABB, _static_aabb: AABB, _movement: Vector2) -> AABB
// {

// }

aabb_draw :: proc(_position: Vector2, _aabb: AABB, _color: Color)
{
	rl.DrawRectangleLines(
		floor_to_int(_aabb.min.x + _position.x),
		floor_to_int(_aabb.min.y + _position.y),
		floor_to_int(_aabb.max.x - _aabb.min.x),
		floor_to_int(_aabb.max.y - _aabb.min.y),
		_color,
	)
}