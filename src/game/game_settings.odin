package game

GameSettings :: struct
{
	agent_speed: f32,

	turret_range: f32,
	turret_bullet_speed: f32,
	turret_cooldown: f32,

	mine_detection_radius: f32,
	mine_explosion_timer: f32,
	mine_explosion_radius: f32,
}

game_settings :: GameSettings {
	agent_speed = 20.0,

	turret_range = 100,
	turret_bullet_speed = 100,
	turret_cooldown = 4,

	mine_detection_radius = 1,
	mine_explosion_timer = 0.5,
	mine_explosion_radius = 5,
}