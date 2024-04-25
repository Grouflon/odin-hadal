package game

import rl "vendor:raylib"

PlayerController :: struct
{
	selection : ^Selection,
}

player_controller_initialize :: proc(using _controller: ^PlayerController)
{
	selection = make_selection()
}

player_controller_shutdown :: proc(using _controller: ^PlayerController)
{
	delete_selection(selection)
}

player_controller_reset :: proc(using _controller: ^PlayerController)
{
	selection_clear(selection)
}

player_controller_update :: proc(using _controller: ^PlayerController, _dt: f32)
{
	selection_update(selection)
	if (mouse().pressed[1])
	{
		for agent in selection.selected_agents
		{
			if (!rl.IsKeyDown(rl.KeyboardKey.LEFT_SHIFT))
			{
				action_system_clear_actions(&agent.action_system)
			}

			if (rl.IsKeyDown(rl.KeyboardKey.LEFT_CONTROL))
			{
				agent_queue_jump(agent, mouse().world_position)
			}
			else if (rl.IsKeyDown(rl.KeyboardKey.A))
			{
				agent_aim(agent, mouse().world_position)
			}
			else
			{
				agent_queue_move_to(agent, mouse().world_position)
			}
		}
	}
	else if (rl.IsKeyDown(rl.KeyboardKey.A))
	{
		for agent in selection.selected_agents
		{
			if (agent.can_aim)
			{
				agent.is_preview_aim = true
			}
		}
	} else if (rl.IsKeyReleased(rl.KeyboardKey.A))
	{
		for agent in selection.selected_agents
		{
			agent.is_preview_aim = false
		}
	}

	if (rl.IsKeyPressed(rl.KeyboardKey.SPACE))
	{
		game().is_game_paused = !game().is_game_paused
	}
}

player_controller_draw :: proc(using _controller: ^PlayerController)
{
	ordered_draw(-2, _controller, proc(_payload: rawptr)
	{
		using controller: = cast(^PlayerController)_payload

		selection_draw_agents(selection)
	})
	
	selection_draw(selection)
}
