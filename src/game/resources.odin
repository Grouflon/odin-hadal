package game

import "hadal:aseprite"

GameResources :: struct
{
	agent_animations: ^AnimationSet
}

game_resources_load :: proc(using _resources: ^GameResources)
{
	_agent_animation_data: = aseprite.load_data("data/sprites/agent.json")
	defer aseprite.free_data(_agent_animation_data)
	agent_animations = make_animation_set(_agent_animation_data)
}

game_resources_unload :: proc(using _resources: ^GameResources)
{
	delete_animation_set(agent_animations)
	agent_animations = nil
}