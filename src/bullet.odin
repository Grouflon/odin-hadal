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

bullet_manager_initialize :: proc(using _manager: ^BulletManager)
{
	update = bullet_update
	entities = make([dynamic]^Bullet)
}

bullet_manager_shutdown :: proc(using _manager: ^BulletManager) {

	for _i := len(entities) - 1; _i >= 0; _i-=1 
    {
    	destroy_bullet(entities[_i])
    }

	delete(entities)
}

Bullet :: struct {
	position: Vector2,
	velocity: Vector2,
	owner: rawptr,
	time: f32
}

create_bullet :: proc(_position: Vector2,_velocity: Vector2, _owner: rawptr) -> ^Bullet 
{
	using bullet := new(Bullet)
	position = _position
	velocity = _velocity
	owner = _owner
	time = 0

	manager_register_entity(&game().bullet_manager, bullet)

	return bullet
}

destroy_bullet:: proc(_bullet: ^Bullet)
{
	manager_unregister_entity(&game().bullet_manager, _bullet)
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

bullet_draw :: proc(_payload: rawptr) {
	using bullet := cast(^Bullet)_payload
	rl.DrawPixelV(floor_vec2(position), rl.BLACK)
}

make_and_register_triple_bullet :: proc(_position: Vector2, _velocity: Vector2, _owner: rawptr)
{
	dir := normalize( _velocity)
	length := length( _velocity)

	create_bullet(_position, _velocity, _owner)
	create_bullet(_position, Vector2{_velocity.y, -_velocity.x}, _owner)
	create_bullet(_position,Vector2{-_velocity.y, _velocity.x}, _owner)
}