package main

import rl "vendor:raylib"
import "core:fmt"

Game :: struct
{
    game_width, game_height : i32,
    pixel_ratio : i32,

    window_width, window_height : i32,

    mouse : Mouse,

    game_render_target : rl.RenderTexture2D,
    game_camera : rl.Camera2D,

    agent_manager : ^AgentManager,
    action_manager : ^ActionManager,
    selection : ^Selection,

    renderer : ^Renderer,
}
g_game : Game

game :: proc() -> ^Game
{
    return &g_game
}

renderer :: proc() -> ^Renderer
{
    return game().renderer
}

mouse :: proc() -> ^Mouse
{
    return &game().mouse
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
    renderer = new(Renderer)
	HideCursor();

    game_render_target = LoadRenderTexture(game_width, game_height);

    game_camera = Camera2D{}
    // game_camera.target -= {30, -30}
    // game_camera.offset += {-20, 20}
    // game_camera.zoom = 4.0
    game_camera.zoom = 1.0

    // Game
    agent_manager = make_agent_manager()
    action_manager = make_action_manager()

    _agents := []^Agent {
        make_agent(Vector2{40,40}),
        make_agent(Vector2{50,40}),
        make_agent(Vector2{40,50}),
        make_agent(Vector2{50,50}),
    }
    for _agent in _agents
    {
        manager_register_entity(agent_manager, _agent)
    }

    selection = make_selection()
}

game_stop :: proc()
{
    using rl
    using g_game

    delete_selection(selection)
    _agents: = agent_manager.entities
    for _agent in _agents
    {
        manager_unregister_entity(agent_manager, _agent)
        delete_agent(_agent)
    }
    delete_action_manager(action_manager)
    delete_agent_manager(agent_manager)

    UnloadRenderTexture(game_render_target)
    CloseWindow()
}

game_update :: proc()
{
	using rl
    using g_game

    mouse_update(&mouse, game_camera, pixel_ratio)

    manager_update(agent_manager)

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

        for _agent in selection.hovered_agents
        {
            _x, _y := floor_to_int(_agent.position.x), floor_to_int(_agent.position.y)
            DrawEllipseLines(
				_x,
                _y,
                5,
                3,
                rl.RAYWHITE)
        }

        for _agent in selection.selected_agents
        {
            _x, _y := floor_to_int(_agent.position.x), floor_to_int(_agent.position.y)
            DrawEllipseLines(
                _x,
                _y,
                5,
                3,
                rl.WHITE)
        }

        renderer_draw(renderer)
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