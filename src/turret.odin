package main
import "core:fmt"
import rl "vendor:raylib"


TurretManager :: struct {
	using Manager(Turret),
}

turret_manager_initialize :: proc(using _manager: ^TurretManager)
{
	update = turret_update
	draw = turret_draw
	destroy_entity = destroy_turret

	manager_initialize(Turret, _manager)
}

turret_manager_shutdown :: proc(using _manager: ^TurretManager) 
{
	manager_shutdown(Turret, _manager)
}

Turret :: struct {
	position: Vector2,
	range:f32,
	cooldown:f32,
	cooldown_timer:f32,
	target:^Agent,
	bullet_func: bullet_func
}

create_turret :: proc(_position: Vector2 ) -> ^Turret {
	using _turret := new(Turret)
	position = _position
	range=1000
	cooldown=0.5
	cooldown_timer=0
	target = nil
	bullet_func = make_and_register_triple_bullet

	manager_register_entity(Turret, &game().turret_manager, _turret)
	return _turret
}

destroy_turret :: proc(_turret: ^Turret) {
	manager_unregister_entity(Turret, &game().turret_manager, _turret)
	free(_turret)
}

turret_update :: proc(using _turret: ^Turret, dt: f32) {

	if (cast(^Agent)target != nil)
	{
		target = nil
	}

	if (cast(^Agent)target == nil)
	{
		target = find_closest_agent(position, range)
	}

	if (cast(^Agent)target != nil)
	{
		cooldown_timer+= dt;

		if (cooldown_timer >= cooldown)
		{
			dir := normalize((cast(^Agent)target).position - position)
			bullet_func(position + dir, dir, _turret)
			cooldown_timer = 0
		}
	}
}

turret_draw :: proc(using _mine: ^Turret) {
	ordered_draw(int(position.y), _mine, proc(_payload: rawptr)
	{
		using _turret := cast(^Turret)_payload
		
		dir := Vector2{0,0}
		if (cast(^Agent)target != nil)
		{ 
			dir = normalize((cast(^Agent)target).position - position)
		}
		pos:=floor_vec2(position)
		rl.DrawPixelV(pos, rl.PINK)
		rl.DrawPixelV(pos + Vector2{0,1}, rl.PINK)
		rl.DrawPixelV(pos + Vector2{0,-1}, rl.PINK)
		rl.DrawPixelV(pos + Vector2{1,0}, rl.PINK)
		rl.DrawPixelV(pos + Vector2{-1,0}, rl.PINK)

		for i:=0; i<2; i+=1
		{
			rl.DrawPixelV(pos+dir*f32(i), rl.BLACK)
		}
	})
}