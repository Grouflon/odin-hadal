package main

import "core:fmt"

import rl "vendor:raylib"

main :: proc()
{
    using rl

	// Misc
    time : f32 = 0.0

    // Window
    game_width, game_height : i32 = 300, 200
    pixel_ratio : i32 = 5
    window_width, window_height : i32 = game_width * pixel_ratio, game_height * pixel_ratio

    InitWindow(window_width, window_height, "Hadal")
    defer CloseWindow()
    SetTargetFPS(60)

    // Rendering
    game_render_target := rl.LoadRenderTexture(game_width, game_height);
    defer UnloadRenderTexture(game_render_target)

    source_rect := Rectangle{ 0.0, 0.0, f32(game_render_target.texture.width), -f32(game_render_target.texture.height) }
    dest_rect := Rectangle{ 0.0, 0.0, f32(window_width), f32(window_height) }

    game_camera := Camera2D{}
    game_camera.zoom = 1.0

    render_camera := Camera2D{}
    render_camera.zoom = 1.0

    // Game
    entity_manager : EntityManager
    agent := make_agent(Vector2{40,40})
    add_entity(&entity_manager, agent)

    // Loop
    for !WindowShouldClose()
    {
        update_entities(&entity_manager)

    	// === DRAW ===
        {
            BeginTextureMode(game_render_target)
            defer EndTextureMode()

            BeginMode2D(game_camera)
            defer EndMode2D()

            ClearBackground(WHITE)
            
            draw_entities(&entity_manager)
        }

        {
            BeginDrawing()
            defer EndDrawing()

            ClearBackground(WHITE)

            {
                BeginMode2D(render_camera)
                defer EndMode2D()

                DrawTexturePro(game_render_target.texture, source_rect, dest_rect, {0.0, 0.0}, 0.0, WHITE)
                DrawFPS(GetScreenWidth() - 95, 10)    
            }
        }
    }
}
