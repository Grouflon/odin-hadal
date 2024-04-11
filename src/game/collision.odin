package game

import "core:math"
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

CheckCollisionRay2dRect :: proc(ray: Ray2d, _bounds: AABB, intersection: ^Vector2) -> bool
{
	using math
	minParam: f32 = F32_MIN
	maxParam: f32 = F32_MAX;
	_x: = _bounds.min.x
	_y: = _bounds.min.y
	_width: = _bounds.max.x
	_height: = _bounds.max.y

	if (ray.direction.x != 0.0)
	{
		txMin: f32 = (_x - ray.origin.x) / ray.direction.x
		txMax: f32 = (_x + _width - ray.origin.x) / ray.direction.x
		minParam = max(minParam, min(txMin, txMax));
		maxParam = min(maxParam, max(txMin, txMax));
	}
	if (ray.direction.y != 0.0)
	{
		tyMin: f32 = (_y - ray.origin.y) / ray.direction.y;
		tyMax: f32 = (_y + _height - ray.origin.y) / ray.direction.y;
		minParam = max(minParam, min(tyMin, tyMax));
		maxParam = min(maxParam, max(tyMin, tyMax));
	}
	// if maxParam < 0, ray is intersecting AABB, but the whole AABB is behind us
	if (maxParam < 0)
	{
		return false;
	}
	// if minParam > maxParam, ray doesn't intersect AABB
	if (minParam > maxParam)
	{
		return false;
	}
	if (intersection != nil)
	{
		_hit_point: = ray.origin + ray.direction * minParam
		intersection.x = _hit_point.x
		intersection.y = _hit_point.y
	}
	return true;
}