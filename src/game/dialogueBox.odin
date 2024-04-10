package game

import rl "vendor:raylib"
import "core:math"
import "core:strings"
import "core:encoding/json"
import "core:fmt"
import "hadal:ldtk"

DialogueBox :: struct
{
	message: cstring,
	choices: [dynamic]^Choice,
	position: Vector2,
}

EAction :: enum u8
{
	CLOSE = 0,
	ROLL_LOOT = 1,
}


create_dialogue_box :: proc(_message: string) -> ^DialogueBox
{
	using _dialogue_box: = new(DialogueBox)

	_data: = ldtk.load_json("data/dialogue.json")
	_dialogues: = _data.(json.Array)

	for _dialogue in _dialogues
	{
		_dialogue_obj: = _dialogue.(json.Object)
		_message: = strings.clone_to_cstring(_dialogue_obj["message"].(json.String))
		message = _message
		_choicesArray: = _dialogue_obj["choices"].(json.Array)
		for _choicea, _index in _choicesArray
		{
			_choice_obj: = _choicea.(json.Object)
			_choice_message: = strings.clone_to_cstring(_choice_obj["message"].(json.String))
			_action: = EAction(_choice_obj["action"].(json.Float))
			_sd: proc() = proc() {  }
			switch (_action)
			{
				case EAction.CLOSE:
				{
					_sd = proc() {  } // replace by action
				}
				case EAction.ROLL_LOOT:
				{
					_sd = proc() {  } // replace by action
				}
			}
			_choice: = create_choice(_choice_message, Vector2{0, 20 * f32(_index + 1)}, Vector2{100, 20},_sd)
			append_elem(&choices, _choice)
		}
	}
	return _dialogue_box
}


dialogue_box_update :: proc(using _dialogue_box: ^DialogueBox)
{
	for choice in choices
	{
		choice_update(choice)
	}
}

dialogue_box_draw :: proc(using _dialogue_box: ^DialogueBox)
{
	using rl
	DrawRectangle(0, 0, 200, 200, WHITE)
	DrawText(message, 0, 0, 10, BLACK)

	for choice in choices
	{
		choice_draw(choice)
	}
}

Choice :: struct
{
	over: bool,
	message: cstring,
	position: Vector2,
	size: Vector2,
	on_click: proc(),
}

create_choice :: proc(_message: cstring, _position: Vector2, _size: Vector2, _on_click: proc()) -> ^Choice
{
	using choice: = new(Choice)
	message = _message
	position = _position
	size = _size
	over = false
	on_click = _on_click

	return choice
}

choice_update :: proc(using _choice: ^Choice)
{
	_mouse: = game().mouse
	_mouse_position: = floor_vec2(_mouse.screen_position)
	_aabb: AABB = {
		min=_mouse_position,
		max=_mouse_position,
	}

	_choise_aabb: AABB = {
		min=position,
		max=position + size,
	}

	over = false

	if (collision_aabb_aabb(_aabb, _choise_aabb))
	{
		if (_mouse.pressed[0])
		{
			on_click()
		}
		over = true
	}
}

choice_draw :: proc(using _choice: ^Choice)
{
	using rl
	_pos: = floor_vec2(position)
	_size: = floor_vec2(size)
	_color: = over ? BLACK : BLUE
	_color_background: = over ? RED : BLANK

	DrawRectangle(i32(_pos.x), i32(_pos.y), i32(_size.x), i32(_size.y), _color_background)
	DrawText(message, i32(_pos.x), i32(_pos.y), 10, _color)

}