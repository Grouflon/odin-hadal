package main
import rl "vendor:raylib"

collision_aabb_aabb :: proc(_a: AABB, _b: AABB) -> bool
{
	return !(
		_a.min.x > _b.max.x ||
		_a.max.x < _b.min.x ||
		_a.min.y > _b.max.y ||
		_a.max.y < _b.min.y)
}

collisionLinePoint :: proc(point:Vector2, p1: Vector2, p2:Vector2) -> bool
{
	return rl.CheckCollisionPointLine(point, p1, p2, 1)
}

CollisionPointCircle :: proc(point:Vector2, center: Vector2, radius:f32) -> bool
{
	return rl.CheckCollisionPointCircle(point, center, radius)
}