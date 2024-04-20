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

	//start
	next_level_index: = level_manager.next_level
	if (len(level_manager.levels) > int(next_level_index))
	{
		previews_level: = level_manager.levels[level_manager.current_level]
		next_level: = level_manager.levels[next_level_index]
		dir: = normalize(next_level.position - previews_level.position)
		if (length(dir) == 0)
		{
			dir.y = -1
		}
		game().game_camera.target = next_level.position
		agents: = get_entities(Agent)
		if (len(agents) > 0)
		{
			offset: f32 = 20
			y: = next_level.position.y + offset * dir.y + next_level.size.y * ((dir.y*dir.y-dir.y)/2)
			for agent in agents
			{
				agent.level_index = next_level_index
				agent.position = Vector2{next_level.position.x + next_level.size.x / 2, y}
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

switch_level_to :: proc(next_level: i32)
{
	level_manager: = &game().level_manager
	if (level_manager.current_level != next_level)
	{
		level_manager.next_level = next_level
		level_manager.switch_level = true
	}
}