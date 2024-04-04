package game

Entity :: struct
{
	position: Vector2,

	type: union{
		^Agent,
		^Mine,
		^Wall,
		^Acid,
		^Ice,
		^Turret,
		^Bullet,
		^Laser,
		^Goal,
		^Swarm,
	}
}
