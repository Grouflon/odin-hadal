package game

Entity :: struct
{
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
