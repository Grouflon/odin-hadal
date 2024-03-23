package main
import rl "vendor:raylib"
import "core:fmt"

MineManager :: struct {
	entities:     [dynamic]^Mine,
	registered:   proc(e: ^Mine),
	unregistered: proc(e: ^Mine),
	update:       proc(e: ^Mine, dt: f32),
}

mine_manager_initialize:: proc(using _manager: ^MineManager)
{
	update = mine_update
	entities = make([dynamic]^Mine)
}

mine_manager_shutdown::proc(using _manager: ^MineManager)
{
	for _i := len(entities)-1; _i > 0; _i-=1
	{
		_mine:=entities[_i]
		manager_unregister_entity(_manager, _mine)
		delete_mine(_mine)
	}

	delete(entities)
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

make_mine :: proc() -> ^Mine {
	return new(Mine)
}

delete_mine :: proc(_mine: ^Mine) {
	free(_mine)
}

mine_initialize::proc(using _mine: ^Mine, _position: Vector2)
{
	position = _position
	is_started = true
	radius = 1
	timer = 0.5
	time = 0
	explosion_radius = 5
}

mine_shutdown::proc(using _mine: ^Mine)
{
	//manager_unregister_entity()
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

	draw(int(position.y), _mine, mine_draw)
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

mine_draw :: proc(_payload: rawptr) {
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
}