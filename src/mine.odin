package main
import rl "vendor:raylib"
import "core:fmt"

MineManager :: struct {
	using Manager(Mine),
}

mine_manager_initialize:: proc(using _manager: ^MineManager)
{
	update = mine_update
	draw = mine_draw
	destroy_entity = destroy_mine

	manager_initialize(Mine, _manager)
}

mine_manager_shutdown::proc(using _manager: ^MineManager)
{
	manager_shutdown(Mine, _manager)
}

Mine :: struct {
	position:         Vector2,
	radius:           f32,
	timer:            f32,
	time:             f32,
	is_started:          bool,
	is_actived:        bool,
	is_boom:           bool,
	has_boom:          bool,
	explosion_radius: f32,
}

create_mine :: proc(_position: Vector2) -> ^Mine {
	using _mine := new(Mine)
	position = _position
	is_started = true
	radius = 1
	timer = 0.5
	time = 0
	explosion_radius = 5

	manager_register_entity(Mine, &game().mine_manager, _mine)

	return _mine
}

destroy_mine :: proc(_mine: ^Mine) {
	manager_unregister_entity(Mine, &game().mine_manager, _mine)
	free(_mine)
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
		for _agent in game().agent_manager.entities {
			if (distance(position, _agent.position) < radius) {
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
	for _agent in game().agent_manager.entities {
		if (distance(position, _agent.position) <= explosion_radius) {
			agent_kill(_agent);
		}
	}

	for mine in game().mine_manager.entities {
		if (mine.is_started && distance(position, mine.position) < explosion_radius) {
			mine_activate(mine)
		}
	}
	is_boom=true
	is_actived=false
	time=0
}

mine_draw :: proc(using _mine: ^Mine) {
	ordered_draw(int(position.y), _mine, proc(_payload: rawptr)
	{
		using mine := cast(^Mine)_payload

		x, y: i32 = floor_to_int(position.x), floor_to_int(position.y)

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