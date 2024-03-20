package main
import rl "vendor:raylib"
import "core:fmt"

Selection :: struct
{
	hovered_agents: [dynamic]^Agent,
	selected_agents: [dynamic]^Agent,
	is_started: bool,
	start: Vector2,
	aabb: [2]Vector2
}


selection_update :: proc(using _selection: ^Selection)
{
	mouse_position : Vector2 = mouse().world_position;
	aabb = {
		mouse_position,
		mouse_position,
	}

	if (rl.IsMouseButtonPressed(rl.MouseButton.LEFT))
	{
		is_started = true
		start = mouse_position
	}
	else if (!rl.IsMouseButtonDown(rl.MouseButton.LEFT) && !rl.IsMouseButtonReleased(rl.MouseButton.LEFT))
	{
		is_started=false
	}

	if (is_started)
	{
		aabb[0] = start
	}
	
	aabb = {
		{
			min(aabb[0].x ,aabb[1].x),
			min(aabb[0].y ,aabb[1].y),	
		},
		{
			max(aabb[0].x ,aabb[1].x),
			max(aabb[0].y, aabb[1].y),
		}
	}
}

selection_draw :: proc(using _selection: ^Selection)
{
	if (!is_started) 
	{
		return
	}

	draw_start : Vector2 = aabb[0]
	draw_size : Vector2 = aabb[1] - aabb[0]

	rl.DrawRectangleV(draw_start, draw_size, rl.BLUE)

}
