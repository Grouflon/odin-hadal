package main

import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

// Array
find :: proc(_array: ^$T/[dynamic]$E, _element: E) -> int
{
	for i := 0; i < len(_array); i+=1
	{
		if (_element == _array[i]) 
		{
			return i
		}
	}
	return -1
}

compare :: proc(_a: $T, _b: T) -> int
{
	if _a < _b { return -1 }
	if _a > _b { return 1 }
	return 0	
}

swap :: proc(_array: ^$T/[dynamic]$E, _index_a: int, _index_b: int)
{
	assert(_index_a >= 0 && _index_a < len(_array))
	assert(_index_b >= 0 && _index_b < len(_array))

	temp: E = _array[_index_a]
	_array[_index_a] = _array[_index_b]
	_array[_index_b] = temp
}

sort :: proc(_array: ^$T/[dynamic]$E, _sort_function: proc(_a: E, _b: E) -> int)
{
	array_length := len(_array)
	for i := 1; i < array_length; i += 1
	{
		for j := i; i >=1; i -= 1
		{
			if (_sort_function(_array[j], _array[j-1]) < 0)
			{
				swap(_array, j, j-1)
			}
			else
			{
				break
			}
		}
	}
}

copy_array :: proc(_dst: ^$T/[dynamic]$E, _src: []E)
{
	resize(_dst, len(_src))
	copy(_dst[:], _src[:])
}

// Math
floor_f32 :: proc(_value: f32) -> f32
{
	return math.floor(_value)
}

floor_vec2 :: proc(_value: Vector2) -> Vector2
{
	return {math.floor(_value.x), math.floor(_value.y) }
}

floor :: proc { floor_vec2, floor_f32 }

normalize_vec2 :: proc(_value: Vector2) -> Vector2
{
	return linalg.normalize0(_value)
}

normalize_vec3 :: proc(_value: Vector3) -> Vector3
{
	return linalg.normalize0(_value)
}

normalize :: proc { normalize_vec2, normalize_vec3 }

ceil_f32 :: proc(_value: f32) -> f32
{
	return math.ceil(_value)
}

ceil_vec2 :: proc(_value: Vector2) -> Vector2
{
	return {math.ceil(_value.x), math.ceil(_value.y)}
}

ceil :: proc { ceil_vec2, ceil_f32 }

floor_to_int :: proc(_value: f32) -> i32
{
	return i32(math.floor(_value))
}

length :: proc(_value: Vector2) -> f32
{
	return linalg.length(_value)
}

length_squared :: proc(_value: Vector2) -> f32
{
	return linalg.length2(_value)
}

distance_squared :: proc(_a: Vector2, _b: Vector2) -> f32
{
	return length_squared(_b - _a)
}

distance :: proc(_a: Vector2, _b: Vector2) -> f32
{
	return math.sqrt(distance_squared(_a, _b))
}