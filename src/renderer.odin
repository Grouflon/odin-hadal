package main

DrawFunction :: proc(_payload : rawptr) 

DrawCall :: struct
{
	priority : int,
	function : DrawFunction,
	payload : rawptr,
}

Renderer :: struct
{
	draw_calls : [dynamic]DrawCall
}

renderer_init :: proc(using _renderer: ^Renderer) 
{
}

renderer_shutdown :: proc(using _renderer: ^Renderer) 
{
	delete(draw_calls)
}

draw :: proc(_priority : int, _payload : rawptr, _draw_function : DrawFunction)
{
	using renderer := renderer()
	new_draw_call := DrawCall {
		priority = _priority,
		function = _draw_function,
		payload = _payload,
	}

	for draw_call, index in draw_calls
	{
		if draw_call.priority <= new_draw_call.priority
		{
			inject_at(&draw_calls, index, new_draw_call)
			return
		} 
	}
	inject_at(&draw_calls, len(draw_calls), new_draw_call)
}

renderer_draw :: proc(using _renderer : ^Renderer)
{
	for draw_call in draw_calls
	{
		draw_call.function(draw_call.payload)
	}
	clear(&draw_calls)
}
