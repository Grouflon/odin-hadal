package main

import rl "vendor:raylib"
import "core:fmt"
import "core:log"

Game :: struct
{
	game_width, game_height : i32,
	pixel_ratio : i32,

	window_width, window_height : i32,

	mouse : Mouse,
	renderer : Renderer,

	game_render_target : rl.RenderTexture2D,
	game_camera : rl.Camera2D,

	entity_manager: EntityManager,

	agent_manager : AgentManager,
	action_manager : ActionManager,

	selection : ^Selection,
	is_game_paused: bool,
	level_data: ^LdtkData
}
g_game : Game

game :: proc() -> ^Game
{
	return &g_game
}

renderer :: proc() -> ^Renderer
{
	return &game().renderer
}

mouse :: proc() -> ^Mouse
{
	return &game().mouse
}

game_initialize :: proc()
{
	using rl
	using g_game

	game_width, game_height = 300, 200
	pixel_ratio = 5
	window_width = game_width * pixel_ratio
	window_height = game_height * pixel_ratio

	InitWindow(window_width, window_height, "Hadal")
	SetTargetFPS(60)

	HideCursor();
	renderer_init(&renderer)

	game_render_target = LoadRenderTexture(game_width, game_height);

	game_camera = Camera2D{}
	game_camera.zoom = 1.0

	// Game
	entity_manager_initialize(&entity_manager)

	entity_manager_register_type(&entity_manager, Agent, agent_definition)
	entity_manager_register_type(&entity_manager, Mine, mine_definition)
	entity_manager_register_type(&entity_manager, Wall, wall_definition)
	entity_manager_register_type(&entity_manager, Acid, acid_definition)
	entity_manager_register_type(&entity_manager, Ice, ice_definition)

	// Uncommenting any of those 3 lines makes the compilation fail for mysterious reasons
	// entity_manager_register_type(&entity_manager, Turret, turret_definition)
	// entity_manager_register_type(&entity_manager, Bullet, bullet_definition)
	// entity_manager_register_type(&entity_manager, Laser, laser_definition)

	game_start()
}

game_start:: proc()
{
	using g_game
	using rl

	level_data = load_level("data/levels/map_ldtk.json")

	agent_manager_initialize(&agent_manager)
	action_manager_initialize(&action_manager)

	for entity in level_data.entities
	{
		position := entity.position // ldtk grid not good scale
		if (entity.identifier == "Agent")
		{
			create_agent(position + Vector2{0, 0})
		}
		else if (entity.identifier == "Mine")
		{
			create_mine(position)
		} 
		else if (entity.identifier == "Acid")
		{
			create_acid(position, Vector2{entity.width, entity.height})
		}
		else if (entity.identifier == "Ice")
		{
			create_ice(position, Vector2{entity.width, entity.height}, 0.3)
		}
		else if (entity.identifier == "Wall")
		{
			create_wall(position, Vector2{entity.width, entity.height})
		}
		// else if (entity.identifier == "Turret")
		// {
		// 	create_turret(position, game_settings.turret_cooldown)
		// }
	}

	selection = make_selection()
}

game_stop :: proc()
{
	using g_game
	using rl

	delete_selection(selection)

	entity_manager_clear_entities(&entity_manager)

	action_manager_shutdown(&action_manager)
	agent_manager_shutdown(&agent_manager)

	free_level(level_data)

}

game_shutdown :: proc()
{
	using rl
	using g_game

	game_stop();

	entity_manager_shutdown(&entity_manager)

	UnloadRenderTexture(game_render_target)

	renderer_shutdown(&renderer)
	CloseWindow()
}

game_update :: proc()
{
	using rl
	using g_game

	_dt: = rl.GetFrameTime()

	if (IsKeyPressed(KeyboardKey.R))
	{
		game_stop();
		game_start()
	}

	mouse_update(&mouse, game_camera, pixel_ratio)
	
	if (IsKeyPressed(KeyboardKey.SPACE))
	{
		is_game_paused = !is_game_paused
	}

	if (!is_game_paused)
	{
		entity_manager_update(&entity_manager, _dt)
	}

	// We dont need selection for now
	// selection_update(selection)
}

game_draw :: proc()
{
	using rl
	using g_game

	// Game render target
	{
		BeginTextureMode(game_render_target)
		defer EndTextureMode()

		BeginMode2D(game_camera)
		defer EndMode2D()

		ClearBackground(GRAY)
		selection_draw_agents(selection)

		entity_manager_draw(&entity_manager)

		renderer_ordered_draw(&renderer)

		selection_draw(selection)
		mouse_draw(&mouse)
	}

	// Scaled up final rendering
	{
		BeginDrawing()
		defer EndDrawing()

		ClearBackground(WHITE)

		render_camera := Camera2D{}
		render_camera.zoom = 1.0
		BeginMode2D(render_camera)
		defer EndMode2D()

		source_rect := Rectangle{ 0.0, 0.0, f32(game_render_target.texture.width), -f32(game_render_target.texture.height) }
		dest_rect := Rectangle{ 0.0, 0.0, f32(window_width), f32(window_height) }
		DrawTexturePro(game_render_target.texture, source_rect, dest_rect, {0.0, 0.0}, 0.0, WHITE)
		DrawFPS(GetScreenWidth() - 95, 10)    
	}
}

game_loop :: proc()
{
	using rl
	using g_game

	for !WindowShouldClose()
	{
		game_update()
		game_draw()
	}
}
