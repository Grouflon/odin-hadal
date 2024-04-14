package game

import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

SMALL_NUMBER :: f32(0.0001)

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

append_unique :: proc(_array: ^$T/[dynamic]$E, _element: E)
{
	_array_length := len(_array)
	for i := 0; i < _array_length; i+=1
	{
		if (_element == _array[i]) 
		{
			return
		}
	}
	append(_array, _element)
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

time_independent_lerp :: proc(_base: f32, _target: f32, _time_to_90: f32, _dt: f32) -> f32
{
	_lambda: = -math.log10_f32(1 - 0.9) / _time_to_90;
	return math.lerp(_base, _target, 1 - math.exp_f32(-_lambda * _dt));
}

trigo_angle :: proc(_direction: Vector2) -> f32
{
	_angle: = (math.atan2(_direction.y, _direction.x) - math.atan2(f32(0), f32(0))) * 180 / math.PI;
	if (_angle < 0) 
	{ 
		_angle += 2 * math.PI;
	}
	return _angle
}

barycentric_coordinates :: proc(_p: Vector2, _a, _b, _c: Vector2) -> (_result: Vector3)
{
	_v0 := _b - _a
	_v1 := _c - _a
	_v2 := _p - _a
	_d00 := linalg.dot(_v0, _v0)
	_d01 := linalg.dot(_v0, _v1)
	_d11 := linalg.dot(_v1, _v1)
	_d20 := linalg.dot(_v2, _v0)
	_d21 := linalg.dot(_v2, _v1)

	_denom := _d00*_d11 - _d01*_d01

	_result.y = (_d11*_d20 - _d01*_d21)/_denom
	_result.z = (_d00*_d21 - _d01*_d20)/_denom
	_result.x = 1 - (_result.z + _result.y)

	return _result
}

is_zero :: proc{ is_zero_vector2, is_zero_f32 }

is_zero_f32 :: proc(_v: f32, _threshold: f32 = SMALL_NUMBER) -> bool
{
	return math.abs(_v) <= SMALL_NUMBER
}

is_zero_vector2 :: proc(_v: Vector2, _threshold: f32 = SMALL_NUMBER) -> bool
{
	return is_zero_f32(_v.x) && is_zero_f32(_v.y)
}
