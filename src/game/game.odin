package game

import rl "vendor:raylib"
import "core:fmt"
import "core:log"
import "hadal:ldtk"

Game :: struct
{
	game_width, game_height : i32,
	pixel_ratio : i32,

	window_width, window_height : i32,

	mouse : Mouse,
	renderer : Renderer,

	game_render_target : rl.RenderTexture2D,
	game_render_target_ui : rl.RenderTexture2D,
	game_camera : rl.Camera2D,

	resources: GameResources,

	entity_manager: EntityManager,

	action_manager: ActionManager,
	animation_manager: AnimationManager,
	physics_manager: PhysicsManager,

	selection : ^Selection,
	is_game_paused: bool,

	current_level: i32,
	switch_level: bool,
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

resources :: proc() -> ^GameResources
{
	return &game().resources
}

physics :: proc() -> ^PhysicsManager
{
	return &game().physics_manager
}

game_initialize :: proc()
{
	using rl
	using g_game

	game_width, game_height = 256, 256
	pixel_ratio = 5
	window_width = game_width * pixel_ratio
	window_height = game_height * pixel_ratio

	InitWindow(window_width, window_height, "Hadal")
	SetTargetFPS(60)

	HideCursor();
	renderer_init(&renderer)

	game_render_target = LoadRenderTexture(game_width, game_height);
	game_render_target_ui = LoadRenderTexture(game_width, game_height);

	game_camera = Camera2D{}
	game_camera.zoom = 1.0

	// Game
	physics_manager_initialize(&physics_manager)
	entity_manager_initialize(&entity_manager)

	// Setup
	entity_manager_register_type(&entity_manager, Agent, agent_definition)
	entity_manager_register_type(&entity_manager, Mine, mine_definition)
	entity_manager_register_type(&entity_manager, Wall, wall_definition)
	entity_manager_register_type(&entity_manager, Acid, acid_definition)
	entity_manager_register_type(&entity_manager, Ice, ice_definition)
	entity_manager_register_type(&entity_manager, Turret, turret_definition)
	entity_manager_register_type(&entity_manager, Bullet, bullet_definition)
	entity_manager_register_type(&entity_manager, Laser, laser_definition)
	entity_manager_register_type(&entity_manager, Goal, goal_definition)
	entity_manager_register_type(&entity_manager, Swarm, swarm_definition)

	physics_manager_set_layer_response(&physics_manager, Layer.Agent, Layer.Agent, .Collide)
	physics_manager_set_layer_response(&physics_manager, Layer.Agent, Layer.Wall, .Collide)

	physics_manager_set_layer_response(&physics_manager, Layer.Swarm, Layer.Swarm, .Collide)
	physics_manager_set_layer_response(&physics_manager, Layer.Swarm, Layer.Wall, .Collide)

	physics_manager_set_layer_response(&physics_manager, Layer.EnemyBullet, Layer.Agent, .Overlap)
	physics_manager_set_layer_response(&physics_manager, Layer.EnemyBullet, Layer.Wall, .Overlap)

	current_level = 0
	switch_level = false

	game_start()
}

game_start:: proc()
{
	using g_game
	using rl

	game_resources_load(&resources)

	animation_manager_initialize(&animation_manager)
	action_manager_initialize(&action_manager)

	selection = make_selection()

	// Create Level
	_levels_data: = ldtk.load_level("data/levels/map_ldtk.json")
	defer ldtk.free_level(_levels_data)
	_level_data: = _levels_data.levels[current_level];

	_start: Vector2 = {150, 150}
	// for _x in 0..<5
	// {
	// 	for _y in 0..<5
	// 	{
	// 		create_swarm(_start + Vector2{ f32(_x*10), f32(_y*10) })
	// 	}
	// }
	
	for entity in _level_data.entities
	{
		position: = entity.position
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
		else if (entity.identifier == "Turret")
		{
			create_turret(position, game_settings.turret_cooldown)
		}
		else if (entity.identifier == "Goal")
		{
			_nextLevel: = entity.customVariables["nextLevel"].value.(i32)
			create_goal(position, Vector2{entity.width, entity.height}, _nextLevel)
		}
	}
}

db: = create_dialogue_box("yoyoyooy")

game_stop :: proc()
{
	using g_game
	using rl

	switch_level = false

	delete_selection(selection)

	entity_manager_clear_entities(&entity_manager)

	action_manager_shutdown(&action_manager)
	animation_manager_shutdown(&animation_manager)

	game_resources_unload(&resources)
}

game_shutdown :: proc()
{
	using rl
	using g_game

	game_stop();

	entity_manager_shutdown(&entity_manager)
	physics_manager_shutdown(&physics_manager)

	UnloadRenderTexture(game_render_target)

	renderer_shutdown(&renderer)
	CloseWindow()
}

game_update :: proc()
{
	using rl
	using g_game

	_dt: = rl.GetFrameTime()

	if (switch_level)
	{
		game_stop()
		game_start()
	}

	if (IsKeyPressed(KeyboardKey.R))
	{
		game_stop()
		game_start()
	}

	if (IsKeyPressed(KeyboardKey.ONE))
	{
		game_stop()
		current_level = 0
		game_start()
	}
	if (IsKeyPressed(KeyboardKey.TWO))
	{
		game_stop()
		current_level = 1
		game_start()
	}
	dialogue_box_update(db)

	mouse_update(&mouse, game_camera, pixel_ratio)
	
	if (IsKeyPressed(KeyboardKey.SPACE))
	{
		is_game_paused = !is_game_paused
	}

	if (!is_game_paused)
	{
		entity_manager_update(&entity_manager, _dt)
		animation_manager_update(&animation_manager, _dt)

		physics_manager_update(&physics_manager)
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

		// physics_manager_draw_layer(&physics_manager, .Agent, RED)
		// physics_manager_draw_layer(&physics_manager, .Wall, BLUE)
		// physics_manager_draw_layer(&physics_manager, .Swarm, YELLOW)

		// selection_draw(selection)

	}

	// Scaled up final rendering
	{
		
		ClearBackground(WHITE)

		render_camera := Camera2D{}
		render_camera.zoom = 1.0
		BeginMode2D(render_camera)
		defer EndMode2D()

		source_rect := Rectangle{ 0.0, 0.0, f32(game_render_target.texture.width), -f32(game_render_target.texture.height) }
		dest_rect := Rectangle{ 0.0, 0.0, f32(window_width), f32(window_height) }
		DrawTexturePro(game_render_target.texture, source_rect, dest_rect, {0.0, 0.0}, 0.0, WHITE)
		DrawFPS(GetScreenWidth() - 95, 10)
	//	dialogue_box_draw(db)
	}

	{
		BeginTextureMode(game_render_target_ui)
		defer EndTextureMode()

		BeginMode2D(game_camera)
		defer EndMode2D()
		ClearBackground(BLANK)

		mouse_draw(&mouse)
	}

	{
		BeginDrawing()
		defer EndDrawing()
		
		source_rect := Rectangle{ 0.0, 0.0, f32(game_render_target_ui.texture.width), -f32(game_render_target_ui.texture.height) }
		dest_rect := Rectangle{ 0.0, 0.0, f32(window_width), f32(window_height) }
		DrawTexturePro(game_render_target_ui.texture, source_rect, dest_rect, {0.0, 0.0}, 0.0, WHITE)
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
