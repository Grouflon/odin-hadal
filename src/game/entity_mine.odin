package game

import rl "vendor:raylib"
import "core:fmt"

Mine :: struct {
	using entity: Entity,
	
	radius:           f32,
	timer:            f32,
	time:             f32,
	is_started:          bool,
	is_actived:        bool,
	is_boom:           bool,
	has_boom:          bool,
	explosion_radius: f32,
}

mine_definition :: EntityDefinition(Mine) {
	update = mine_update,
	draw = mine_draw,
}

create_mine :: proc(_position: Vector2) -> ^Mine {
	using _mine := new(Mine)
	entity.type = _mine
	entity.position = _position
	
	is_started = true
	radius = game_settings.mine_detection_radius
	timer = game_settings.mine_explosion_timer
	time = 0
	explosion_radius = game_settings.mine_explosion_radius

	register_entity(_mine)

	return _mine
}

mine_update :: proc(using _mine: ^Mine, dt: f32) {
	if (is_boom) {
		time += rl.GetFrameTime()
		if (time > 1) {
			is_boom = false
			has_boom = true
		}
	}

	if (is_started) {
		for _agent in get_entities(Agent) {
			if (distance(entity.position, _agent.position) < radius) {
				mine_activate(_mine)
			}
		}
	}

	if (is_actived) {
		time += rl.GetFrameTime()
		if (time > timer) {
			mine_explode(_mine)
		}
	}
}

mine_activate :: proc(using _mine: ^Mine) {
	is_actived = true
	is_started = false
}

mine_explode :: proc(using _mine: ^Mine) {
	for _agent in get_entities(Agent) {
		if (distance(entity.position, _agent.position) <= explosion_radius) {
			agent_kill(_agent);
		}
	}

	for mine in get_entities(Mine) {
		if (mine.is_started && distance(entity.position, mine.position) < explosion_radius) {
			mine_activate(mine)
		}
	}
	is_boom=true
	is_actived=false
	time=0
}

mine_draw :: proc(using _mine: ^Mine) {
	ordered_draw(int(entity.position.y), _mine, proc(_payload: rawptr)
	{
		using mine := cast(^Mine)_payload

		x, y: i32 = floor_to_int(entity.position.x), floor_to_int(entity.position.y)

		if (has_boom) {

		} else if (is_boom) {
			rl.DrawPixel(x, y, rl.GREEN)
			rl.DrawCircle(x, y, explosion_radius, rl.RED)
		} else if (is_actived) {
			rl.DrawPixel(x, y, rl.RED)
		} else {
			rl.DrawPixel(x, y, rl.BLACK)
		}
	})
}