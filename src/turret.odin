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
	range:i32,
	cooldown:f32,
	cooldown_timer:f32,
	target:rawptr
}

make_turret :: proc(_position: Vector2) -> ^Turret {
	using Turret := new(Turret)
	position = _position
	range=30
  	cooldown=0.5
  	cooldown_timer=0
	return Turret
}

delete_turret :: proc(_turret: ^Turret) {
	free(_turret)
}

turret_update :: proc(using _turret: ^Turret, dt: f32) {
	cooldown_timer+= dt;

	if (cooldown_timer >= cooldown)
	{
		bullet := make_bullet(position, Vector2{5,5}, _turret)
		manager_register_entity(game().bullet_manager, bullet)
		cooldown_timer = 0
	}
	
	draw(int(position.y), _turret, turret_draw)
}

turret_draw :: proc(_payload: rawptr) {
	using turret := cast(^Turret)_payload
	
	pos:=floor_vec2(position)
	rl.DrawPixelV(pos, rl.PINK)
	rl.DrawCircleV(pos, 1, rl.PINK)
}