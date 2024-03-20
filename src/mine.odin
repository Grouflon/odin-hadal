package main
import rl "vendor:raylib"
import "core:fmt"

MineManager :: struct {
	entities:     [dynamic]^Mine,
	registered:   proc(e: ^Mine),
	unregistered: proc(e: ^Mine),
	update:       proc(e: ^Mine),
}

make_mine_manager :: proc() -> ^MineManager {
	manager := new(MineManager)
	manager.update = mine_update

	return manager
}

delete_mine_manager :: proc(_manager: ^MineManager) {
	delete(_manager.entities)
	free(_manager)
}

Mine :: struct {
	position:         Vector2,
	radius:           f32,
	timer:            f32,
	time:             f32,
	isstart:          bool,
	isactived:        bool,
	isboom:           bool,
	hasboom:          bool,
	explosion_radius: f32,
}

make_mine :: proc(_position: Vector2) -> ^Mine {
	using mine := new(Mine)
	position = _position
	isstart = true
	radius = 1
	timer = 0.5
	time = 0
	explosion_radius = 5

	return mine
}

delete_mine :: proc(_mine: ^Mine) {
	free(_mine)
}

mine_update :: proc(using _mine: ^Mine) {
	if (isboom) {
		time += rl.GetFrameTime()
		if (time > 1) {
			isboom = false
			hasboom = true
		}
	}

	if (isstart) {
		for _agent in game().agent_manager.entities {
			if (distance_squared(position, _agent.position) < radius) {
				mine_activate(_mine)
			}
		}
	}

	if (isactived) {
		time += rl.GetFrameTime()
		if (time > timer) {
			mine_explode(_mine)
		}
	}

	draw(int(position.y), _mine, mine_draw)
}

mine_activate :: proc(using _mine: ^Mine) {
	isactived = true
	isstart = false
}

mine_explode :: proc(using _mine: ^Mine) {
	for _agent in game().agent_manager.entities {
		if (distance_squared(position, _agent.position) < explosion_radius) {
			//agent_kill(_agent);
		}
	}

	for mine in game().mine_manager.entities {
		if (mine.isstart && distance_squared(position, mine.position) < explosion_radius) {
			mine_activate(mine)
		}
	}
	isboom=true
	isactived=false
	time=0
}

mine_draw :: proc(_payload: rawptr) {
	using mine := cast(^Mine)_payload

	x, y: i32 = floor_to_int(position.x), floor_to_int(position.y)

	if (hasboom) {

	} else if (isboom) {
		rl.DrawPixel(x, y, rl.GREEN)
		rl.DrawCircle(x, y, explosion_radius, rl.RED)
	} else if (isactived) {
		rl.DrawPixel(x, y, rl.RED)
	} else {
		rl.DrawPixel(x, y, rl.BLACK)
	}
}