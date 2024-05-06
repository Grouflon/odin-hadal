package game

import rl "vendor:raylib"

PlayerAgentInfo :: struct
{
	agent: ^Agent,
	name: string,
}

PlayerController :: struct
{
	selection: ^Selection,
	player_agents: [dynamic]PlayerAgentInfo,
}

player_controller_initialize :: proc(using _controller: ^PlayerController)
{
	selection = make_selection()
	player_agents = make([dynamic]PlayerAgentInfo)
}

player_controller_shutdown :: proc(using _controller: ^PlayerController)
{
	for player_agent in player_agents
	{
		delete(player_agent.name)
	}
	delete(player_agents)
	delete_selection(selection)
}

player_controller_reset :: proc(using _controller: ^PlayerController)
{
	selection_clear(selection)
}

player_controller_update :: proc(using _controller: ^PlayerController, _dt: f32)
{
	agent_keys: []rl.KeyboardKey = {
		rl.KeyboardKey.ONE,
		rl.KeyboardKey.TWO,
		rl.KeyboardKey.THREE,
		rl.KeyboardKey.FOUR,
		rl.KeyboardKey.FIVE,
		rl.KeyboardKey.SIX,
	}

	is_shift_down: = rl.IsKeyDown(rl.KeyboardKey.LEFT_SHIFT)
	select_all: = rl.IsKeyPressed(rl.KeyboardKey.GRAVE)

	for agent_info, i in player_agents
	{
		if select_all
		{
			selection_add_agent(selection, agent_info.agent)
		}
		else if (rl.IsKeyPressed(agent_keys[i]))
		{
			if !is_shift_down
			{
				selection_clear(selection)
			}
			selection_add_agent(selection, agent_info.agent)
		}
	}

	selection_update(selection)
	if (mouse().pressed[1])
	{
		for agent in selection.selected_agents
		{
			if !is_shift_down
			{
				action_system_clear_actions(&agent.action_system)
			}

			if (rl.IsKeyDown(rl.KeyboardKey.LEFT_CONTROL))
			{
				agent_queue_jump(agent, mouse().world_position)
			}
			else if (rl.IsKeyDown(rl.KeyboardKey.A))
			{
				agent_fire(agent, mouse().world_position)
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
			agent_aim(agent, true)
		}
	} else if (rl.IsKeyReleased(rl.KeyboardKey.A))
	{
		for agent in selection.selected_agents
		{
			agent_aim(agent, false)
		}
	}

	if (rl.IsKeyPressed(rl.KeyboardKey.SPACE))
	{
		game().is_game_paused = !game().is_game_paused
	}

	if (rl.IsKeyPressed(rl.KeyboardKey.R))
	{
		game_request_reset()
	}

	if (rl.IsKeyPressed(rl.KeyboardKey.F1))
	{
		request_level_change(0)
	}
	if (rl.IsKeyPressed(rl.KeyboardKey.F2))
	{
		request_level_change(1)
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
