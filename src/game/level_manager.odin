package game

import "hadal:ldtk"

LevelManager :: struct
{
	levels: [dynamic]LevelInfo,
	current_level: i32,
}

LevelInfo :: struct
{
	camera_position: Vector2
}

level_manager_initialize:: proc(level_manager: ^LevelManager)
{
	_levels_data: = ldtk.load_level("data/levels/map_ldtk.json")
	defer ldtk.free_level(_levels_data)
	for level, index in _levels_data.levels
	{
		level_info: = load_level(level, i32(index))
		append(&level_manager.levels, level_info)
	}
}

level_manager_start :: proc(level_manager: ^LevelManager, current_level: i32)
{
	bullets: = get_entities(Bullet)

	for bullet in bullets
	{
		entity_manager_unregister_entity(&game().entity_manager, bullet)
	}

	if (len(level_manager.levels) > int(current_level))
	{
		game().game_camera.target = level_manager.levels[current_level].camera_position
		agents: = get_entities(Agent)
		if (len(agents) > 0)
		{
			for agent in agents
			{
				agent.level_index = current_level
			}
		}
	}
}

level_manager_shutdown :: proc(level_manager: ^LevelManager)
{
	delete(level_manager.levels)
}

load_level :: proc(level: ^ldtk.LdtkLevel, index: i32) -> LevelInfo
{
	level_info: LevelInfo
	level_info.camera_position = level.position

	for entity in level.entities
	{
		entity_: ^Entity = nil;
		position: = entity.position + level.position
		if (entity.identifier == "Agent")
		{
			agents: = get_entities(Agent)
			if (len(agents) == 0)
			{
				entity_ = create_agent(position + Vector2{0, 0})
			}
		}
		else if (entity.identifier == "Mine")
		{
			entity_ = create_mine(position)
		} 
		else if (entity.identifier == "Acid")
		{
			entity_ = create_acid(position, Vector2{entity.width, entity.height})
		}
		else if (entity.identifier == "Ice")
		{
			entity_ = create_ice(position, Vector2{entity.width, entity.height}, 0.3)
		}
		else if (entity.identifier == "Wall")
		{
			entity_ = create_wall(position, Vector2{entity.width, entity.height})
		}
		else if (entity.identifier == "Turret")
		{
			entity_ = create_turret(position, game_settings.turret_cooldown)
		}
		else if (entity.identifier == "Goal")
		{
			_nextLevel: = entity.customVariables["nextLevel"].value.(i32)
			entity_ = create_goal(position, Vector2{entity.width, entity.height}, _nextLevel)
		}

		if (entity_ != nil)
		{
			entity_.level_index = index
		}
	}

	return level_info
}