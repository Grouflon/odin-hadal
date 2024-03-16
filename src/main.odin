package main

import "core:fmt"

import rl "vendor:raylib"

main :: proc()
{
	// Misc
    time : f32 = 0.0

    // Window
    game_width, game_height : i32 = 300, 200
    pixel_ratio : i32 = 4
    window_width, window_height : i32 = game_width * pixel_ratio, game_height * pixel_ratio

    rl.InitWindow(window_width, window_height, "Hadal")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)

    // Loop
    for !rl.WindowShouldClose()
    {
    	// Draw
    	{
            rl.ClearBackground(rl.WHITE)

            rl.BeginDrawing()
            defer rl.EndDrawing()

            rl.DrawFPS(rl.GetScreenWidth() - 95, 10)    
        }
    }
}
