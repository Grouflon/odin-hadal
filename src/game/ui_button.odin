package game

import rl "vendor:raylib"
import "core:math"
import "core:strings"
import "core:fmt"

Button :: struct
{
	over: bool,
	text: cstring,
	position: Vector2,
	size: Vector2,
	on_click: proc(),
}

create_button :: proc(_text: cstring, _position: Vector2, _size: Vector2, _on_click: proc()) -> ^Button
{
	using button: = new(Button)
	text = _text
	position = _position
	size = _size
	over = false
	on_click = _on_click

	return button
}

button_update :: proc(using _button: ^Button)
{
	mouse: = game().mouse
	mouse_position: = floor_vec2(mouse.screen_position)
	mouse_aabb: AABB = {
		min = mouse_position,
		max = mouse_position,
	}

	button_aabb: AABB = {
		min = position,
		max = position + size,
	}

	over = false

	if (collision_aabb_aabb(button_aabb, mouse_aabb))
	{
		if (mouse.pressed[0])
		{
			game().mouse.pressed[0] = false
			on_click()
		}
		over = true
	}
}

button_shutdown :: proc(using _button: ^Button)
{
	delete(text)
}

button_draw :: proc(_button: ^Button)
{
	using rl
	pos: = floor_vec2(_button.position)
	size: = floor_vec2(_button.size)
	color: = _button.over ? BLACK : BLUE
	color_background: = _button.over ? RED : BLANK
	font_size: f32 = 10

	text_info: = MeasureTextEx(resources().text_font, _button.text, font_size, 0.0)
	text_center_pos: = Vector2{
		pos.x + size.x / 2 - text_info.x / 2,
		pos.y + size.y / 2 - text_info.y / 2,
	}

	DrawRectangleV(pos, size, color_background)
	DrawRectangleLinesEx(Rectangle{pos.x, pos.y, size.x, size.y}, 2, BLACK)
	DrawTextEx(resources().text_font, _button.text, text_center_pos, font_size, 0.0, color)
}