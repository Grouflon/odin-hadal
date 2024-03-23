package main

import rl "vendor:raylib"
import "core:fmt"

Game :: struct
{
	game_width, game_height : i32,
	pixel_ratio : i32,

	window_width, window_height : i32,

	mouse : Mouse,
	renderer : Renderer,

	game_render_target : rl.RenderTexture2D,
	game_camera : rl.Camera2D,

	agent_manager : AgentManager,
	mine_manager : MineManager,
	bullet_manager : BulletManager,
	laser_manager : LaserManager,
	turret_manager : TurretManager,
	acid_manager : AcidManager,
	ice_manager : IceManager,
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
	// game_camera.target -= {30, -30}
	// game_camera.offset += {-20, 20}
	// game_camera.zoom = 4.0
	game_camera.zoom = 1.0

	// Game
	game_start()
}

game_start:: proc()
{
	using g_game
	agent_manager_initialize(&agent_manager)
	mine_manager_initialize(&mine_manager)
	bullet_manager_initialize(&bullet_manager)
	laser_manager_initialize(&laser_manager)
	turret_manager_initialize(&turret_manager)
	acid_manager_initialize(&acid_manager)
	ice_manager_initialize(&ice_manager)
	action_manager_initialize(&action_manager)

	level_data = load_level("map_ldtk.json")

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
		else if (entity.identifier == "Turret")
		{
			create_turret(position, 4)
		}
		else if (entity.identifier == "Acid")
		{
			create_acid(position, Vector2{entity.width, entity.height})
		}
		else if (entity.identifier == "Ice")
		{
			create_ice(position, Vector2{entity.width, entity.height}, 0.3)
		}
	}

	selection = make_selection()
}

game_stop :: proc()
{
	using g_game

	free_level(level_data)

	delete_selection(selection)

	action_manager_shutdown(&action_manager)
	mine_manager_shutdown(&mine_manager)
	bullet_manager_shutdown(&bullet_manager)
	laser_manager_shutdown(&laser_manager)
	turret_manager_shutdown(&turret_manager)
	acid_manager_shutdown(&acid_manager)
	ice_manager_shutdown(&ice_manager)
	agent_manager_shutdown(&agent_manager)
}

game_shutdown :: proc()
{
	using rl
	using g_game

	game_stop();

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
		manager_update(Bullet, &bullet_manager, _dt)
		manager_update(Agent, &agent_manager, _dt)
		manager_update(Acid, &acid_manager, _dt)
		manager_update(Ice, &ice_manager, _dt)
		manager_update(Mine, &mine_manager, _dt)
		manager_update(Laser, &laser_manager, _dt)
		manager_update(Turret, &turret_manager, _dt)
	}

	selection_update(selection)
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

		manager_draw(Bullet, &bullet_manager)
		manager_draw(Agent, &agent_manager)
		manager_draw(Mine, &mine_manager)
		manager_draw(Turret, &turret_manager)
		manager_draw(Laser, &laser_manager)
		manager_draw(Acid, &acid_manager)
		manager_draw(Ice, &ice_manager)

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