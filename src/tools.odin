package main

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