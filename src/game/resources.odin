package game

import "hadal:aseprite"
import rl "vendor:raylib"

GameResources :: struct
{
	agent_animations: ^AnimationSet,
	cursor_texture: rl.Texture2D,
	swarm_texture: rl.Texture2D,
	text_font: rl.Font,
}

game_resources_load :: proc(using _resources: ^GameResources)
{
	_agent_animation_data: = aseprite.load_data("data/sprites/agent.json")
	defer aseprite.free_data(_agent_animation_data)
	agent_animations = make_animation_set(_agent_animation_data)

	cursor_texture = rl.LoadTexture("data/sprites/cursor.png")
	swarm_texture = rl.LoadTexture("data/sprites/swarm.png")

	text_font = rl.LoadFont("data/fonts/pixelify.fnt")
}

game_resources_unload :: proc(using _resources: ^GameResources)
{
	rl.UnloadFont(text_font)

	rl.UnloadTexture(swarm_texture)
	rl.UnloadTexture(cursor_texture)

	delete_animation_set(agent_animations)
	agent_animations = nil
}