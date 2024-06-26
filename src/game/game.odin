package game

import rl "vendor:raylib"
import "core:fmt"
import "core:log"
import "core:strings"
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

	should_reset: bool,

	pause_button: ^Button,
	dialogue_button: ^Button,
	is_show_dialogue: bool,
	can_pause: bool,
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
	SetExitKey(.KEY_NULL)

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

	// ui
	pause_button = create_button("PAUSE", Vector2{100, 10}, Vector2{50,20}, game_pause)
	dialogue_button = create_button("?", Vector2{150, 10}, Vector2{50,20}, game_dialogue)
	can_pause = true

	game_start()
}

game_shutdown :: proc()
{
	using rl
	using g_game

	game_stop()

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

	player_controller_initialize(&player_controller)

	agent_count: i32 = game_settings.agent_number
	for i: i32 = 0; i < agent_count; i += 1
	{
		player_agent: PlayerAgentInfo
		player_agent.agent = create_agent({128, 128}, .PLAYER)
		player_agent.name = fmt.aprintf("AGENT %d", i + 1)

		append(&player_controller.player_agents, player_agent)
	}

	request_level_change(0)
}

game_stop :: proc()
{
	using g_game
	should_reset = false

	player_controller_shutdown(&player_controller)
	entity_manager_clear_entities(&entity_manager)
	level_manager_clear(&level_manager)
}

game_request_reset :: proc()
{
	using g_game
	should_reset = true
}

game_dialogue :: proc()
{
	using g_game
	is_game_paused = true
	can_pause = false
	is_show_dialogue = !is_show_dialogue
}

game_pause :: proc()
{
	using g_game
	if (can_pause)
	{
		is_game_paused = !is_game_paused
	}
}

game_update :: proc()
{
	using rl
	using g_game

	_dt: = rl.GetFrameTime()
	time += _dt

	level_manager_update(&level_manager)

	mouse_update(&mouse, game_camera, pixel_ratio)

	button_update(pause_button)
	button_update(dialogue_button)

	if (is_show_dialogue && level_manager.levels[level_manager.current_level].dialogue != nil)
	{
		dialogue_box_update(level_manager.levels[level_manager.current_level].dialogue)
	}

	player_controller_update(&player_controller, _dt)

	if (!is_game_paused)
	{
		entity_manager_update(&entity_manager, _dt)
		animation_manager_update(&animation_manager, _dt)

		physics_manager_update(&physics_manager)
	}
}

draw_agent_hud :: proc( _position: Vector2, _agent_info: PlayerAgentInfo, _agent_index: i32)
{
	is_selected: = selection_is_agent_selected(game().player_controller.selection, _agent_info.agent)

	// Avatar
	avatar_size: = Vector2{ 10, 10 }
	margin: f32 = 1.0 
	avatar_box_size: = avatar_size + {margin, margin} * 2.0
	rl.DrawRectangleV(_position, avatar_box_size, rl.WHITE)
	rl.DrawRectangleLines(
		i32(_position.x),
		i32(_position.y), 
		i32(avatar_size.x + margin * 2.0),
		i32(avatar_size.y + margin * 2.0),
		is_selected ? rl.YELLOW : rl.BLACK
	)
	rl.DrawTextureRec(
		resources().agent_animations.texture,
		{
			36,0,
			avatar_size.x, avatar_size.y
		},
		_position + { margin, margin },
		rl.WHITE
	)

	// Name
	name_position: = Vector2{ _position.x + avatar_box_size.x + 2.0, _position.y}
	name: = strings.clone_to_cstring(_agent_info.name, context.temp_allocator)
	rl.DrawTextEx(resources().text_font, name, name_position, 6, 0.0, is_selected ? rl.YELLOW : rl.WHITE)

	// Bars
	bars_position: = Vector2{ _position.x, _position.y + avatar_box_size.y + 2.0}
	bar_height: f32 = 3.0
	health_ratio: f32 = f32(_agent_info.agent.health) / f32(_agent_info.agent.health_max)
	rl.DrawRectangleV(bars_position, { avatar_box_size.x, bar_height }, rl.BLACK)
	rl.DrawRectangleV(bars_position, { avatar_box_size.x * health_ratio, bar_height }, rl.GREEN)
}

game_draw :: proc()
{
	using rl
	using g_game

	// Game render target
	{
		BeginTextureMode(game_render_target)
		defer EndTextureMode()
		ClearBackground(GRAY)

		{
			BeginMode2D(game_camera)
			defer EndMode2D()

			entity_manager_draw(&entity_manager)

			renderer_ordered_draw(&renderer)

			// physics_manager_draw_layer(&physics_manager, .Agent, RED)
			// physics_manager_draw_layer(&physics_manager, .Wall, BLUE)
			// physics_manager_draw_layer(&physics_manager, .Swarm, YELLOW)

			player_controller_draw(&player_controller)
		}

		{
			ui_camera: = rl.Camera2D{ zoom = 1.0 }
			BeginMode2D(ui_camera)
			defer EndMode2D()

			hud_column_count: i32 = i32(len(player_controller.player_agents))
			hud_column_size: = i32(game_width) / hud_column_count
			for i: i32 = 0; i < hud_column_count; i += 1
			{
				draw_agent_hud({f32(5 + hud_column_size * i), f32(game_height - 20)}, player_controller.player_agents[i], 0)
			}

			// DrawText("Hello World!", 0, 0, 1, rl.BLUE);
			// DrawTextEx(resources.text_font, "AGENT 1", {0,0}, 6, 0.0, rl.BLUE);
		}
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

		button_draw(pause_button)
		button_draw(dialogue_button)

		if (is_show_dialogue && level_manager.levels[level_manager.current_level].dialogue != nil)
		{
			dialogue_box_draw(level_manager.levels[level_manager.current_level].dialogue)
		}
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

		if should_reset
		{
			game_stop()
			game_start()
		}
	}
}
