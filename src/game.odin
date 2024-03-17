package main

import rl "vendor:raylib"

Game :: struct
{
    game_width, game_height : i32,
    pixel_ratio : i32,

    window_width, window_height : i32,

    game_render_target : rl.RenderTexture2D,
    game_camera : rl.Camera2D,

    entity_manager : EntityManager,
}
g_game : Game

game :: proc() -> ^Game
{
    return &g_game
}

game_start :: proc()
{
    using rl
    using g_game

    game_width, game_height = 300, 200
    pixel_ratio = 5
    window_width = game_width * pixel_ratio
    window_height = game_height * pixel_ratio

    InitWindow(window_width, window_height, "Hadal")
    SetTargetFPS(60)

    game_render_target = LoadRenderTexture(game_width, game_height);

    game_camera = Camera2D{}
    game_camera.zoom = 1.0

    // Game
    agent := make_agent(Vector2{40,40})
    add_entity(&entity_manager, agent)
}

game_stop :: proc()
{
    using rl
    using g_game

    UnloadRenderTexture(game_render_target)
    CloseWindow()
}

game_update :: proc()
{
	using rl
    using g_game

    update_entities(&entity_manager)
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
        
        draw_entities(&entity_manager)

        DrawLine(20,20,230,150,RED)
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