package main

import "core:math"

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

floor_vec2 :: proc(_value: Vector2) -> Vector2
{
	return {math.floor(_value.x), math.floor(_value.y)}
}