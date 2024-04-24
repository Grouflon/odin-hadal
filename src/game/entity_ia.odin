package game

import rl "vendor:raylib"

Ia :: struct {
	using entity: Entity,
	agent: ^Agent,
	direction: f32,
}

ia_definition :: EntityDefinition(Ia) {
	update = ia_update,
}

create_ia :: proc(_position: Vector2, _level_index: i32) -> ^Ia 
{
	using ia: = new(Ia)
	entity.type = ia
	entity.level_index = _level_index

	direction = 1

	agent = create_agent(_position, .ENEMY)
	agent.level_index = _level_index
	
	register_entity(ia)
	return ia
}

ia_update :: proc(using _ia: ^Ia, dt: f32)
{
	if (agent != nil && agent.is_alive)
	{
		if (len(agent.action_system.action_queue) == 0)
		{
			direction *= -1
			agent_queue_move_to(agent, agent.position + Vector2{60 * direction, 0})
		}
	}
}