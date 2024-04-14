package game

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

Turret :: struct {
	using entity: Entity,
	
	position: Vector2,
	range:f32,
	cooldown:f32,
	cooldown_timer:f32,
	target: ^Agent,
	has_target: bool,
	target_lock: Vector2,
	has_target_lock: bool,
	bullet_speed: f32,
	bullet_func: bullet_func
}

turret_definition :: EntityDefinition(Turret) {

	update = turret_update,
	draw = turret_draw,
}

create_turret :: proc(_position: Vector2, _cooldown: f32) -> ^Turret {
	using _turret := new(Turret)
	entity.type = _turret
	
	position = _position
	range = game_settings.turret_range
	cooldown = _cooldown
	cooldown_timer = 0
	bullet_speed = game_settings.turret_bullet_speed
	bullet_func = create_bullet_fire

	register_entity(_turret)
	return _turret
}

turret_update :: proc(using _turret: ^Turret, dt: f32) 
{
	if (target != nil && !target.is_alive)
	{
		target = nil
		reset_turret(_turret)
	}

	if (target == nil)
	{
		target = find_closest_agent(position, range)
	}

	has_target = target != nil
	if (!has_target){ return }

	if (cooldown_timer == 0)
	{
		target_lock = target.position
		has_target_lock = true
	}

	cooldown_timer+= dt;

	if (cooldown_timer >= cooldown)
	{
		dir := normalize(target_lock - position)
		bullet_func(position + dir, dir * bullet_speed, _turret)
		reset_turret(_turret)
	}
}

reset_turret:: proc(using _turret: ^Turret)
{
	cooldown_timer = 0
	has_target_lock = false
}

turret_draw :: proc(using _turret: ^Turret) {
	ordered_draw(int(position.y), _turret, proc(_payload: rawptr)
	{
		using _turret: = cast(^Turret)_payload
		using rl

		dir: = Vector2{0,0}
		pos: = floor_vec2(position)
		// turret
		DrawPixelV(pos, rl.PINK)
		DrawPixelV(pos + Vector2{0,1}, rl.PINK)
		DrawPixelV(pos + Vector2{0,-1}, rl.PINK)
		DrawPixelV(pos + Vector2{1,0}, rl.PINK)
		DrawPixelV(pos + Vector2{-1,0}, rl.PINK)

		if (has_target_lock)
		{ 
			dir = normalize(target_lock - position)

			_raycast_result: [dynamic]RaycastResult
			physics_raycast(.Wall, pos + dir, dir, 400, &_raycast_result)

			if (len(_raycast_result) > 0)
			{
				DrawLineV(pos + dir, _raycast_result[0].hit_point, GREEN)
			}
			delete(_raycast_result)

			angle: = trigo_angle(dir)
			rect: Rectangle = {pos.x,pos.y, 2, 200}

		} else if (has_target)
		{
			dir = normalize(target.position - position)
		}
		
		// canon
		for i: =0; i < 2; i += 1
		{
			DrawPixelV(pos+dir*f32(i), rl.BLACK)
		}
	})
}