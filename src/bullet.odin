package main
import rl "vendor:raylib"
import "core:fmt"


BulletManager :: struct {
	entities:     [dynamic]^Bullet,
	registered:   proc(e: ^Bullet),
	unregistered: proc(e: ^Bullet),
	update:       proc(e: ^Bullet, dt: f32),
}

make_bullet_manager :: proc() -> ^BulletManager {
	manager := new(BulletManager)
	manager.update = bullet_update

	return manager
}

delete_bullet_manager :: proc(_manager: ^BulletManager) {

	_bullets: = _manager.entities
	for _bullet in _bullets
    {
        manager_unregister_entity(_manager, _bullet)
        delete_bullet(_bullet)
    }

	delete(_manager.entities)
	free(_manager)
}

Bullet :: struct {
	position: Vector2,
	velocity: Vector2,
	owner: rawptr,
	time: f32
}

make_bullet :: proc(_position: Vector2,_velocity: Vector2, _owner: rawptr) -> ^Bullet {
	using bullet := new(Bullet)
	position = _position
	velocity = _velocity
	owner = _owner
	time = 0
	return bullet
}

delete_bullet :: proc(_bullet: ^Bullet) {
	free(_bullet)
}

bullet_update :: proc(using _bullet: ^Bullet, dt: f32) {
	position += velocity*dt
	time+=dt

	if (time >= 5)
	{
		manager_unregister_entity(game().bullet_manager, _bullet)
		return
	}
	draw(int(position.y), _bullet, bullet_draw)
}

bullet_draw :: proc(_payload: rawptr) {
	using bullet := cast(^Bullet)_payload
	rl.DrawPixelV(floor_vec2(position), rl.BLACK)
}