package game
import rl "vendor:raylib"

Weapon :: struct
{
	using entity: Entity,

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
	parent: ^Entity,
}

weapon_definition :: EntityDefinition(Weapon) {

	update = weapon_update,
	draw = weapon_draw,
}

create_weapon :: proc(_parent: ^Entity, _aim_timer: f32, _reload_timer: f32) -> ^Weapon
{
	using weapon: = new(Weapon)
	entity.type = weapon
	parent = _parent
	can_aim = true
	aim_timer = _aim_timer
	aim_cooldown = aim_timer

	reload_timer = _reload_timer
	reload_cooldown = reload_timer

	register_entity(weapon)
	return weapon
}

weapon_update :: proc(using _weapon: ^Weapon, _dt: f32)
{
	if (is_reloading && cooldown_timer(is_reloading, &reload_cooldown, reload_timer, _dt))
	{
		is_reloading = false
		can_aim = true
	}

	if (is_preview_aim)
	{
		aim_target = game().mouse.world_position
	}

	if (is_aiming)
	{
		if (cooldown_timer(is_aiming, &aim_cooldown, aim_timer, _dt))
		{
			is_aiming = false
			is_reloading = true
			direction: = normalize(aim_target - parent.position)
			create_bullet_fire(weapon_get_start_position(_weapon), direction * 50, parent, .AllyBullet)
		}
	}
}

weapon_draw :: proc(_weapon: ^Weapon)
{
	ordered_draw(-1, _weapon, proc(_payload: rawptr)
	{
		using weapon: = cast(^Weapon)_payload

		if (is_preview_aim || is_aiming)
		{
			weapon_draw_fire_angle(weapon_get_start_position(weapon), aim_target)
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

weapon_get_start_position :: proc(using _weapon: ^Weapon) -> Vector2
{
	direction: = normalize(aim_target - parent.position)
	return parent.position + direction * 10
}