package main
import rl "vendor:raylib"
import "core:fmt"


TurretManager :: struct {
	entities:     [dynamic]^Turret,
	registered:   proc(e: ^Turret),
	unregistered: proc(e: ^Turret),
	update:       proc(e: ^Turret, dt: f32),
}

make_turret_manager :: proc() -> ^TurretManager 
{
	manager := new(TurretManager)
	manager.update = turret_update

	return manager
}

delete_turret_manager :: proc(_manager: ^TurretManager) 
{
	_turrets: = _manager.entities
    for _turret in _turrets
    {
        manager_unregister_entity(_manager, _turret)
        delete_turret(_turret)
    }

	delete(_manager.entities)
	free(_manager)
}

Turret :: struct {
	position: Vector2,
	range:f32,
	cooldown:f32,
	cooldown_timer:f32,
	target:^Agent,
	bullet_func: bullet_func
}

make_turret :: proc(_position: Vector2, ) -> ^Turret {
	using turret := new(Turret)
	position = _position
	range=1000
  	cooldown=0.5
  	cooldown_timer=0
	target = nil
	bullet_func = make_triple_bullet_registor
	return turret
}

delete_turret :: proc(_turret: ^Turret) {
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
	
	draw(int(position.y), _turret, turret_draw)
}

turret_draw :: proc(_payload: rawptr) {
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
}