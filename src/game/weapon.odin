package game
import rl "vendor:raylib"

Weapon :: struct
{
	is_preview_aim: bool,
	aim_target: Vector2,
	can_aim: bool,
	is_aiming: bool,
	aim_cooldown: f32,
	aim_timer: f32,

	is_firing: bool,
	fire_cooldown: f32,
	fire_timer: f32,

	is_reloading: bool,
	reload_cooldown: f32,
	reload_timer: f32,
	entity: ^Entity,
}

create_weapon :: proc(_entity: ^Entity, _aim_timer: f32, _reload_timer: f32) -> ^Weapon
{
	using weapon: = new(Weapon)
	entity = _entity
	can_aim = true
	aim_timer = _aim_timer
	aim_cooldown = aim_timer

	reload_timer = _reload_timer
	reload_cooldown = reload_timer

	return weapon
}

weapon_update :: proc(using _weapon: ^Weapon, _dt: f32)
{
	if (is_reloading && cooldown_timer(is_reloading, &reload_cooldown, reload_timer, _dt))
	{
		is_reloading = false
		can_aim = true
	}

	if (is_aiming)
	{
		if (cooldown_timer(is_aiming, &aim_cooldown, aim_timer, _dt))
		{
			is_aiming = false
			is_reloading = true
			direction: = normalize(aim_target - entity.position)
			create_bullet_fire(entity.position + direction * 10, direction * 50, entity, .AllyBullet)
		}
	}
}

weapon_draw :: proc(_weapon: ^Weapon)
{
	ordered_draw(-1, _weapon, proc(_payload: rawptr)
	{
		using weapon: = cast(^Weapon)_payload

		if (is_preview_aim)
		{
			aim_target_temp: = game().mouse.world_position
			weapon_draw_fire_angle(entity.position, aim_target_temp)
		}
		if (is_aiming)
		{
			weapon_draw_fire_angle(entity.position, aim_target)
		}
	})
}

weapon_draw_fire_angle :: proc(start: Vector2, target: Vector2)
{
	angle: f32 = 10 * rl.DEG2RAD
	aim_direction: = target - start
	babord: = rl.Vector2Rotate(aim_direction, -angle/2)
	tribord: = rl.Vector2Rotate(aim_direction, angle/2)

	rl.DrawLineV(start, start + babord * 500, rl.PINK)
	rl.DrawLineV(start, start + tribord * 500, rl.PINK)
}

weapon_aiming :: proc(using _weapon: ^Weapon, _isAiming: bool)
{
	if (can_aim && _isAiming)
	{
		is_preview_aim = true
		return
	}
	
	is_preview_aim = false
}

weapon_fire :: proc(using _weapon: ^Weapon, _target: Vector2)
{
	if (can_aim)
	{
		can_aim = false
		is_aiming = true
		is_preview_aim = false
		aim_target = _target
	} 
}

weapon_stop :: proc(using _weapon: ^Weapon)
{
	is_preview_aim = false
	is_aiming = false
}