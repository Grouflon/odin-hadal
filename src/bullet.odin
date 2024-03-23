package main
import rl "vendor:raylib"
import "core:fmt"

bullet_func :: proc(position: Vector2, _velocity:Vector2, _owner:rawptr)

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
	_agents := game().agent_manager.entities
	speed:f32= 10
	position += velocity * dt * speed
	time+=dt
	aabb := AABB{position,position}
	
	for _agent in _agents
	{
		if (_agent.is_alive && collision_aabb_aabb( aabb,agent_aabb(_agent)))
		{
			agent_kill(_agent)
			destroy_bullet(_bullet)
			return
		}
	}

	if (time >= 3)
	{
		destroy_bullet(_bullet)
		return
	}

	draw(int(position.y), _bullet, bullet_draw)
}

destroy_bullet:: proc(_bullet: ^Bullet)
{
	manager_unregister_entity(game().bullet_manager, _bullet)
	delete_bullet(_bullet)
}

bullet_draw :: proc(_payload: rawptr) {
	using bullet := cast(^Bullet)_payload
	rl.DrawPixelV(floor_vec2(position), rl.BLACK)
}


make_bullet_registor :: proc(_position: Vector2,_velocity: Vector2, _owner: rawptr)
{
	bullet := make_bullet(_position, _velocity, _owner)
	manager_register_entity(game().bullet_manager, bullet)
}

make_triple_bullet_registor :: proc(_position: Vector2, _velocity: Vector2, _owner: rawptr)
{
	dir := normalize( _velocity)
	length := length( _velocity)

	make_bullet_registor(_position, _velocity, _owner)
	make_bullet_registor(_position, Vector2{_velocity.y, -_velocity.x}, _owner)
	make_bullet_registor(_position,Vector2{-_velocity.y, _velocity.x}, _owner)
}