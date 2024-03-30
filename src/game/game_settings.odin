package game

GameSettings :: struct
{
	agent_max_speed: f32,
	agent_acceleration: f32,
	agent_deceleration: f32,

	turret_range: f32,
	turret_bullet_speed: f32,
	turret_cooldown: f32,

	mine_detection_radius: f32,
	mine_explosion_timer: f32,
	mine_explosion_radius: f32,
}

game_settings :: GameSettings {
	agent_max_speed = 25.0,
	agent_acceleration = 150.0,
	agent_deceleration = 85.0,

	turret_range = 100,
	turret_bullet_speed = 100,
	turret_cooldown = 4,

	mine_detection_radius = 1,
	mine_explosion_timer = 0.5,
	mine_explosion_radius = 5,
}