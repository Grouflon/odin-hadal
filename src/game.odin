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
    mine_manager : ^MineManager,
    bullet_manager : ^BulletManager,
    turret_manager : ^TurretManager,
    action_manager : ^ActionManager,
    selection : ^Selection,

	ldtk:ldtk
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
	mine_manager= make_mine_manager();
	bullet_manager= make_bullet_manager();
	turret_manager= make_turret_manager();
    action_manager = make_action_manager()

	ldtk = load_ldtk( "map_ldtk.json")

	for entity in ldtk.entities
	{
		position := entity.position*10 // ldtk grid not good scale
		if (entity.id == 3)// agent
		{
            create_agent(position + Vector2{0, 0})
            create_agent(position + Vector2{10, 0})
            create_agent(position + Vector2{0, 10})
            create_agent(position + Vector2{10, 10})
		}
		else if (entity.id == 5) // mine
		{
			manager_register_entity(mine_manager, make_mine(position))

		} 
		else if (entity.id == 6) // turret
		{
			manager_register_entity(turret_manager, make_turret(position))
		}
	}

    selection = make_selection()
}

game_stop :: proc()
{
	using g_game

	delete(ldtk.entities)

    delete_selection(selection)
    delete_action_manager(action_manager)
    delete_mine_manager(mine_manager)
    delete_bullet_manager(bullet_manager)
    delete_turret_manager(turret_manager)
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

    // manager_update(bullet_manager, _dt)
    manager_update(Agent, &agent_manager, _dt)
    // manager_update(mine_manager, _dt)
    // manager_update(turret_manager, _dt)

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

        // manager_draw(bullet_manager)
        manager_draw(Agent, agent_manager)
        // manager_draw(mine_manager)
        // manager_draw(turret_manager)

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