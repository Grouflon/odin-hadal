package main

collision_aabb_aabb :: proc(_a: AABB, _b: AABB) -> bool
{
	return !(
	    _a.min.x > _b.max.x ||
	    _a.max.x < _b.min.x ||
	    _a.min.y > _b.max.y ||
	    _a.max.y < _b.min.y
    )
}