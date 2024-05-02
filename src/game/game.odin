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

	animation_manager: AnimationManager,
	physics_manager: PhysicsManager,
	level_manager: LevelManager,

	time: f32,
	is_game_paused: bool,

	player_controller: PlayerController,
	player_agents: [dynamic]^Agent,

	should_reset: bool,
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
	draw_init()

	game_render_target = LoadRenderTexture(game_width, game_height);
	game_render_target_ui = LoadRenderTexture(game_width, game_height);

	game_camera = Camera2D{}
	game_camera.zoom = 1

	// Game
	physics_manager_initialize(&physics_manager)
	animation_manager_initialize(&animation_manager)
	entity_manager_initialize(&entity_manager)

	// Setup
	entity_manager_register_type(&entity_manager, Agent, agent_definition)
	entity_manager_register_type(&entity_manager, Ia, ia_definition)
	entity_manager_register_type(&entity_manager, Mine, mine_definition)
	entity_manager_register_type(&entity_manager, Wall, wall_definition)
	entity_manager_register_type(&entity_manager, Acid, acid_definition)
	entity_manager_register_type(&entity_manager, Ice, ice_definition)
	entity_manager_register_type(&entity_manager, Turret, turret_definition)
	entity_manager_register_type(&entity_manager, Bullet, bullet_definition)
	entity_manager_register_type(&entity_manager, Laser, laser_definition)
	entity_manager_register_type(&entity_manager, Goal, goal_definition)
	entity_manager_register_type(&entity_manager, Swarm, swarm_definition)
	entity_manager_register_type(&entity_manager, Weapon, weapon_definition)

	physics_manager_set_layer_response(&physics_manager, Layer.Agent, Layer.Agent, .Collide)
	physics_manager_set_layer_response(&physics_manager, Layer.Agent, Layer.Wall, .Collide)

	physics_manager_set_layer_response(&physics_manager, Layer.Swarm, Layer.Swarm, .Collide)
	physics_manager_set_layer_response(&physics_manager, Layer.Swarm, Layer.Wall, .Collide)

	physics_manager_set_layer_response(&physics_manager, Layer.EnemyBullet, Layer.Agent, .Overlap)
	physics_manager_set_layer_response(&physics_manager, Layer.EnemyBullet, Layer.Wall, .Overlap)

	physics_manager_set_layer_response(&physics_manager, Layer.AllyBullet, Layer.Turret, .Overlap)
	physics_manager_set_layer_response(&physics_manager, Layer.AllyBullet, Layer.EnemyAgent, .Overlap)

	game_resources_load(&resources)
	level_manager_initialize(&level_manager)
	player_controller_initialize(&player_controller)

	game_start()
}

game_shutdown :: proc()
{
	using rl
	using g_game

	game_stop()

	player_controller_shutdown(&player_controller)
	level_manager_shutdown(&level_manager)
	game_resources_unload(&resources)
	entity_manager_clear_entities(&entity_manager)
	entity_manager_shutdown(&entity_manager)
	animation_manager_shutdown(&animation_manager)
	physics_manager_shutdown(&physics_manager)

	UnloadRenderTexture(game_render_target)

	draw_shutdown()
	renderer_shutdown(&renderer)
	CloseWindow()
}

game_start :: proc()
{
	using g_game

	time = 0.0

	player_agents = make([dynamic]^Agent)
	agent_count: i32 = game_settings.agent_number
	for i: i32 = 0; i < agent_count; i += 1
	{
		agent: = create_agent({128, 128}, .PLAYER)
		// agent.level_index = next_level_index
		append(&player_agents, agent)
	}

	request_level_change(0)
}

game_stop :: proc()
{
	using g_game

	player_controller_reset(&player_controller)
	entity_manager_clear_entities(&entity_manager)
	level_manager_clear(&level_manager)

	delete(player_agents)
}

db: = create_dialogue_box("yoyoyooy")

game_request_reset :: proc()
{
	using g_game

	should_reset = true
}

game_update :: proc()
{
	using rl
	using g_game

	_dt: = rl.GetFrameTime()
	time += _dt

	level_manager_update(&level_manager)

	dialogue_box_update(db)

	mouse_update(&mouse, game_camera, pixel_ratio)

	player_controller_update(&player_controller, _dt)

	if (!is_game_paused)
	{
		entity_manager_update(&entity_manager, _dt)
		animation_manager_update(&animation_manager, _dt)

		physics_manager_update(&physics_manager)
	}

	if should_reset
	{
		game_stop()
		game_start()
	}
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

		entity_manager_draw(&entity_manager)

		renderer_ordered_draw(&renderer)

		// physics_manager_draw_layer(&physics_manager, .Agent, RED)
		// physics_manager_draw_layer(&physics_manager, .Wall, BLUE)
		// physics_manager_draw_layer(&physics_manager, .Swarm, YELLOW)

		player_controller_draw(&player_controller)
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
		// dialogue_box_draw(db)
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
