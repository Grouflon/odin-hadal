package game

import rl "vendor:raylib"
import "core:math"
import "core:strings"
import "core:encoding/json"
import "core:runtime"
import "core:fmt"
import "hadal:tools"

DialogueBox :: struct
{
	messages: [dynamic]^Message,
	current_message: ^Message,
	position: Vector2,
	size: Vector2,
}

EAction :: enum u8
{
	CLOSE = 0,
	GO_TO = 1,
}


create_dialogue_box :: proc(_text: string, _position: Vector2, _size: Vector2) -> ^DialogueBox
{
	using _dialogue_box: = new(DialogueBox)

	position = _position
	size = _size

	_data: = tools.parse_string(_text)
	defer json.destroy_value(_data)
	_dialogues: = _data.(json.Array)

	for _dialogue in _dialogues
	{
		message_temp: = create_message(_dialogue.(json.Object), _position)
		append_elem(&messages, message_temp)
	}

	if (len(messages) > 0)
	{
		current_message = messages[0]
	}

	return _dialogue_box
}

dialogue_box_shutdown :: proc(using _dialogue_box: ^DialogueBox)
{
	for message in messages
	{
		message_shutdown(message)
	}
	free(_dialogue_box)
}

dialogue_box_update :: proc(using _dialogue_box: ^DialogueBox)
{
	if (current_message != nil)
	{
		message_update(current_message)
	}
}

dialogue_box_draw :: proc(using _dialogue_box: ^DialogueBox)
{
	using rl
	DrawRectangleV(position, size, WHITE)
	if (current_message != nil)
	{
		message_draw(current_message)
	}
}

dialogue_box_goto :: proc(using _dialogue_box: ^DialogueBox, index: int)
{
	if (len(messages) > index)
	{
		current_message = messages[index]
	}
}

dialogue_resume_game :: proc()
{
	using game: = game()
	can_pause = true
	is_game_paused = false
	is_show_dialogue = false
}


Message :: struct
{
	text: cstring,
	choices: [dynamic]^Button,
	position: Vector2,
}

create_message :: proc(_message: json.Object, _position: Vector2) -> ^Message
{
	using message: = new(Message)
	position = _position

	text = strings.clone_to_cstring(_message["message"].(json.String))

	choicesArray: = _message["choices"].(json.Array)
	for choice, index in choicesArray
	{
		choice_obj: = choice.(json.Object)
		choice_message: = strings.clone_to_cstring(choice_obj["message"].(json.String))
		action: = EAction(choice_obj["action"].(json.Float))
		button_action: proc () = proc () {}

		switch (action)
		{
			case EAction.CLOSE:
			{
				button_action = dialogue_resume_game
			}
			case EAction.GO_TO:
			{
				/*goto: = int(choice_obj["target"].(json.Float))

				button_action = proc () {
					context = runtime.default_context()

					dialogue_box: = game().level_manager.levels[game().level_manager.current_level].dialogue
					
					if (dialogue_box != nil)
					{
						dialogue_box_goto(dialogue_box, goto) 
					}
				}*/
			}
		}

		button_position: = Vector2{_position.x, _position.y + 20 * f32(index + 1)}
		_choice: = create_button(choice_message, button_position, Vector2{100, 20}, button_action)
		append_elem(&choices, _choice)
	}

	return message
}

message_update :: proc(using _message: ^Message)
{
	for choice in choices
	{
		button_update(choice)
	}

	
	if (len(choices) == 0 && game().mouse.pressed[0])
	{
		dialogue_resume_game()
	}
}


message_draw :: proc(using _message: ^Message)
{
	rl.DrawTextEx(resources().text_font, text, position, 6, 0.0, rl.BLACK)
	for choice in choices
	{
		button_draw(choice)
	}
}

message_shutdown :: proc(using _message: ^Message)
{
	delete(text)
	for choice in choices
	{
		button_shutdown(choice)
		free(choice)
	}
	delete(choices)

}