package game

import "hadal:ldtk"

LevelManager :: struct
{
	levels: [dynamic]LevelInfo,
	current_level: i32,
	requested_level: i32,
}

LevelInfo :: struct
{
	position: Vector2,
	size: Vector2
}

level_manager_initialize:: proc(_level_manager: ^LevelManager)
{
	levels_data: = ldtk.load_level("data/levels/map_ldtk.json")
	defer ldtk.free_level(levels_data)
	_level_manager.current_level = -1
	for level, index in levels_data.levels
	{
		level_info: = load_level(level, i32(index))
		append(&_level_manager.levels, level_info)
	}
}

level_manager_go_to_level :: proc(_level_manager: ^LevelManager, _level_index: i32)
{
	if (_level_manager.current_level == _level_index) { return }
	if (_level_index < 0 || int(_level_index) >= len(_level_manager.levels)) { return }

	// stop
	bullets: = get_entities(Bullet)
	for bullet in bullets
	{
		entity_manager_unregister_entity(&game().entity_manager, bullet)
	}

	agents: = get_entities(Agent)
	for agent in agents
	{
		agent_reset(agent)
	}

	turrets: = get_entities(Turret)
	for turret in turrets
	{
		turret_reset(turret)
	}

	//start
	if (_level_manager.current_level >= 0)
	{
		previews_level: = _level_manager.levels[_level_manager.current_level]
		next_level: = _level_manager.levels[_level_index]
		dir: = normalize(next_level.position - previews_level.position)
		game().game_camera.target = next_level.position

		offset: f32 = 20
		y: = next_level.position.y + offset * dir.y + next_level.size.y * ((dir.y*dir.y-dir.y)/2)
		for agent in game().player_agents
		{
			if (agent.is_alive)
			{
				agent.level_index = _level_index
				agent.position = Vector2{next_level.position.x + next_level.size.x / 2, y}
			}
		}
	}
	_level_manager.current_level = _level_index
}


level_manager_clear:: proc(_level_manager: ^LevelManager)
{
	clear(&_level_manager.levels)
}


level_manager_shutdown :: proc(_level_manager: ^LevelManager)
{
	delete(_level_manager.levels)
}

load_level :: proc(level: ^ldtk.LdtkLevel, index: i32) -> LevelInfo
{
	level_info: LevelInfo
	level_info.position = level.position
	level_info.size = level.size

	for entity in level.entities
	{
		entity_tmp: ^Entity = nil;
		position: = entity.position + level.position
		if (entity.identifier == "Agent")
		{
			entity_tmp = create_ia(position, index)
		}
		else if (entity.identifier == "Mine")
		{
			entity_tmp = create_mine(position)
		} 
		else if (entity.identifier == "Acid")
		{
			entity_tmp = create_acid(position, Vector2{entity.width, entity.height})
		}
		else if (entity.identifier == "Ice")
		{
			entity_tmp = create_ice(position, Vector2{entity.width, entity.height}, 0.3)
		}
		else if (entity.identifier == "Wall")
		{
			entity_tmp = create_wall(position, Vector2{entity.width, entity.height})
		}
		else if (entity.identifier == "Turret")
		{
			entity_tmp = create_turret(position, game_settings.turret_cooldown)
		}
		else if (entity.identifier == "Goal")
		{
			_nextLevel: = entity.customVariables["nextLevel"].value.(i32)
			entity_tmp = create_goal(position, Vector2{entity.width, entity.height}, _nextLevel)
		}

		if (entity_tmp != nil)
		{
			entity_tmp.level_index = index
		}
	}

	return level_info
}

level_manager_request_level_change :: proc(_level_manager: ^LevelManager, _level_index: i32)
{
	_level_manager.requested_level = _level_index
}

level_manager_update :: proc(_level_manager: ^LevelManager)
{
	if (_level_manager.requested_level >= 0)
	{
		level_manager_go_to_level(_level_manager, _level_manager.requested_level)
		_level_manager.requested_level = -1
	}
}

request_level_change :: proc(_level_index: i32)
{
	level_manager_request_level_change(&game().level_manager, _level_index)
}