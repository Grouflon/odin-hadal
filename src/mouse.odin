package main

import rl "vendor:raylib"
import "core:math"

Mouse :: struct
{
	screen_position : Vector2,
	world_position : Vector2,
	pressed : [2]bool,
	released : [2]bool,
	down : [2]bool,
}

mouse_update :: proc(using _mouse:^Mouse, _camera:rl.Camera2D, _pixel_ratio:i32)
{
	screen_position = rl.GetMousePosition();
	world_position = ((((screen_position) / f32(_pixel_ratio)) - _camera.offset) / _camera.zoom) + _camera.target // Magic formula, figured it out just by trying out things until it displayed what I want

	pressed = {
		rl.IsMouseButtonPressed(rl.MouseButton.LEFT),
		rl.IsMouseButtonPressed(rl.MouseButton.RIGHT),
	}

	released = {
		rl.IsMouseButtonReleased(rl.MouseButton.LEFT),
		rl.IsMouseButtonReleased(rl.MouseButton.RIGHT),
	}

	down = {
		rl.IsMouseButtonDown(rl.MouseButton.LEFT),
		rl.IsMouseButtonDown(rl.MouseButton.RIGHT),
	}
}

mouse_draw :: proc(using _mouse:^Mouse)
{
	rl.DrawPixel(i32(math.floor(world_position.x)), i32(math.floor(world_position.y)), rl.GREEN)
}