package game

import rl "vendor:raylib"
import "core:fmt"

Bullet :: struct {
	using entity: Entity,
	
	position: Vector2,
	velocity: Vector2,
	owner: rawptr,
	time: f32,

	collider: ^Collider,
}

bullet_definition :: EntityDefinition(Bullet) {
	update = bullet_update,
	draw = bullet_draw,
	shutdown = bullet_shutdown,
}

bullet_func :: proc(_position: Vector2, _velocity:Vector2, _owner:rawptr)

create_bullet_fire :: proc(_position: Vector2,_velocity: Vector2, _owner: rawptr)
{
	create_bullet(_position, _velocity,_owner)
}

create_bullet :: proc(_position: Vector2,_velocity: Vector2, _owner: rawptr) -> ^Bullet 
{
	using bullet: = new(Bullet)
	entity.type = bullet
	
	position = _position
	velocity = _velocity
	owner = _owner
	time = 0
	collider = create_collider(
		bullet,
		AABB{
			{0, 0},
			{1, 1},
		},
		.EnemyBullet,
		.Dynamic,
	)

	register_entity(bullet)

	return bullet
}

bullet_shutdown :: proc(using _bullet: ^Bullet)
{
	destroy_collider(collider)
}

bullet_update :: proc(using _bullet: ^Bullet, dt: f32)
{
	position += velocity * dt
	time += dt

	has_collided: = false
	for overlap in collider.overlaps
	{
		#partial switch e in overlap.entity.type
		{
			case ^Agent:
				agent_kill(e)
				has_collided = true

			case ^Wall:
				has_collided = true
		}
	}

	if (has_collided || time >= 3)
	{
		destroy_entity(_bullet)
		return
	}
}

bullet_draw :: proc(using _bullet: ^Bullet) {
	ordered_draw(int(position.y), _bullet, proc(_payload: rawptr)
	{
		using bullet: = cast(^Bullet)_payload
		rl.DrawPixelV(floor_vec2(position), rl.BLACK)
	})
}

make_and_register_triple_bullet :: proc(_position: Vector2, _velocity: Vector2, _owner: rawptr)
{
	dir: = normalize( _velocity)
	length: = length( _velocity)

	create_bullet(_position, _velocity, _owner)
	create_bullet(_position, Vector2{_velocity.y, -_velocity.x}, _owner)
	create_bullet(_position,Vector2{-_velocity.y, _velocity.x}, _owner)
}
