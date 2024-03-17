package main
import rl "vendor:raylib"
import "core:fmt"
Selection :: struct
{
	using entity : Entity,

	hovered_agents: [dynamic]^Agent,
	selected_agents: [dynamic]^Agent,
	isStarted: bool,
	start: [2]f32,
	aabb: [4]f32
}


selection_update :: proc(_entity: ^Entity)
{
	using selection := cast(^Selection)_entity
	sposition : rl.Vector2 = rl.GetMousePosition();
	aabb = {
		sposition[0],
		sposition[1],
		sposition[0],
		sposition[1],
	}

	if (rl.IsMouseButtonPressed(rl.MouseButton.LEFT))
	{
		isStarted = true
		start = {sposition[0],
			sposition[1],}
	}
	else if (!rl.IsMouseButtonDown(rl.MouseButton.LEFT) && !rl.IsMouseButtonReleased(rl.MouseButton.LEFT))
	{
		isStarted=false
	}

	if (isStarted)
	{
		aabb[0] = start[0]
		aabb[1]= start[1]
	}
	
	aabb = {
		min(aabb[0],aabb[2]),
		min(aabb[1],aabb[3]),
		max(aabb[0],aabb[2]),
		max(aabb[1],aabb[3]),
	}
}

selection_draw :: proc(_entity: ^Entity)
{
	using selection := cast(^Selection)_entity
	ballPosition : rl.Vector2 = rl.GetMousePosition();
	rl.DrawCircleV(ballPosition, 40, rl.MAROON);

	if (!isStarted) 
	{
		return
	}

	rl.DrawRectangle(cast(i32)aabb[0],cast(i32)aabb[1],cast(i32)aabb[2],cast(i32)aabb[3], rl.BLUE)
}

selection_make :: proc() -> ^Selection
{
	using selection := new(Selection)
	update = selection_update
	draw = selection_draw
	return selection
}