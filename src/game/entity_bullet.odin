package game

import rl "vendor:raylib"
import "core:fmt"

Bullet :: struct {
	using entity: Entity,
	
	position: Vector2,
	velocity: Vector2,
	owner: rawptr,
	time: f32,
	raycast_result: [dynamic]RaycastResult,
}

bullet_definition :: EntityDefinition(Bullet) {
	update = bullet_update,
	draw = bullet_draw,
}

bullet_func :: proc(position: Vector2, _velocity: Vector2, _owner:rawptr)

create_bullet_fire :: proc(_position: Vector2,_velocity: Vector2, _owner: rawptr)
{
	create_bullet(_position, _velocity,_owner)
}

create_bullet :: proc(_position: Vector2,_velocity: Vector2, _owner: rawptr) -> ^Bullet 
{
	using bullet := new(Bullet)
	entity.type = bullet
	
	position = _position
	velocity = _velocity
	owner = _owner
	time = 0

	physics_raycast(.Wall, _position, normalize_vec2(velocity), 400, &raycast_result)
	register_entity(bullet)

	return bullet
}

bullet_shutdown :: proc(using _agent: ^Bullet)
{
	delete(raycast_result)
}

bullet_update :: proc(using _bullet: ^Bullet, dt: f32) {	
	position += velocity * dt
	time+=dt
	aabb := AABB{position,position}
	
	_agents := get_entities(Agent)
	for _agent in _agents
	{
		if (_agent.is_alive && collision_aabb_aabb( aabb,agent_aabb(_agent)))
		{
			agent_kill(_agent)
			destroy_entity(_bullet)
			return
		}
	}

	_walls := get_entities(Wall)
	for _wall in _walls
	{
		if (collision_aabb_aabb(aabb,wall_aabb(_wall)))
		{
			destroy_entity(_bullet)
			return
		}
	}

	if (time >= 3)
	{
		destroy_entity(_bullet)
		return
	}
}

bullet_draw :: proc(using _bullet: ^Bullet) {
	ordered_draw(int(position.y), _bullet, proc(_payload: rawptr)
	{
		using bullet: = cast(^Bullet)_payload
		using rl
		if (len(raycast_result) > 0)
		{
			DrawLineV(position, raycast_result[0].hit_point, BLUE)
		}
		DrawPixelV(floor_vec2(position), rl.BLACK)
	})
}

make_and_register_triple_bullet :: proc(_position: Vector2, _velocity: Vector2, _owner: rawptr)
{
	dir := normalize( _velocity)
	length := length( _velocity)

	create_bullet(_position, _velocity, _owner)
	create_bullet(_position, Vector2{_velocity.y, -_velocity.x}, _owner)
	create_bullet(_position,Vector2{-_velocity.y, _velocity.x}, _owner)
}