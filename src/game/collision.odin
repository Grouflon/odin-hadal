package game

import rl "vendor:raylib"

collision_aabb_aabb :: proc(_a: AABB, _b: AABB) -> bool
{
	return !(
		_a.min.x >= _b.max.x ||
		_a.max.x <= _b.min.x ||
		_a.min.y >= _b.max.y ||
		_a.max.y <= _b.min.y)
}

collision_line_point :: proc(_point: Vector2, _p1: Vector2, _p2: Vector2) -> bool
{
	return rl.CheckCollisionPointLine(_point, _p1, _p2, 1)
}

collision_point_circle :: proc(_point: Vector2, _center: Vector2, _radius: f32) -> bool
{
	return rl.CheckCollisionPointCircle(_point, _center, _radius)
}