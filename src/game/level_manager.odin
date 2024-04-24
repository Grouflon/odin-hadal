package game

import "hadal:ldtk"

LevelManager :: struct
{
	levels: [dynamic]LevelInfo,
	current_level: i32,
	switch_level: bool,
	next_level: i32,
}

LevelInfo :: struct
{
	position: Vector2,
	size: Vector2
}

level_manager_initialize:: proc(level_manager: ^LevelManager)
{
	_levels_data: = ldtk.load_level("data/levels/map_ldtk.json")
	defer ldtk.free_level(_levels_data)
	level_manager.current_level = 0
	for level, index in _levels_data.levels
	{
		level_info: = load_level(level, i32(index))
		append(&level_manager.levels, level_info)
	}
}

level_manager_start :: proc(level_manager: ^LevelManager)
{
	// stop
	bullets: = get_entities(Bullet)
	for bullet in bullets
	{
		entity_manager_unregister_entity(&game().entity_manager, bullet)
	}
	level_manager.switch_level = false

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
	next_level_index: = level_manager.next_level
	if (len(level_manager.levels) > int(next_level_index))
	{
		previews_level: = level_manager.levels[level_manager.current_level]
		next_level: = level_manager.levels[next_level_index]
		dir: = normalize(next_level.position - previews_level.position)
		game().game_camera.target = next_level.position

		agents_player: [dynamic]^Agent
		defer(delete(agents_player))
		for agent in agents
		{
			if (agent.team == .PLAYER)
			{
				append(&agents_player, agent)
			}
		}
		

		if (len(agents_player) > 0)
		{
			offset: f32 = 20
			y: = next_level.position.y + offset * dir.y + next_level.size.y * ((dir.y*dir.y-dir.y)/2)
			for agent in agents_player
			{
				if (agent.is_alive)
				{
					agent.level_index = next_level_index
					agent.position = Vector2{next_level.position.x + next_level.size.x / 2, y}
				}
			}
		}
		else
		{
			nbr_agent: i32 = game_settings.agent_number
			for i: i32 = 0; i < nbr_agent; i += 1
			{
				agent: = create_agent(Vector2{next_level.size.x / 2 + 5 * f32(i), next_level.size.y / 2}, .PLAYER)
				agent.level_index = next_level_index
			}
		}

		level_manager.current_level = next_level_index
	}
}


level_manager_clear:: proc(level_manager: ^LevelManager)
{
	clear(&level_manager.levels)
}


level_manager_shutdown :: proc(level_manager: ^LevelManager)
{
	delete(level_manager.levels)
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

switch_level_to :: proc(next_level: i32)
{
	level_manager: = &game().level_manager
	if (level_manager.current_level != next_level)
	{
		level_manager.next_level = next_level
		level_manager.switch_level = true
	}
}