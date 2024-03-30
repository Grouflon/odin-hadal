package game

import rl "vendor:raylib"

Vector2 :: [2]f32
Vector3 :: [3]f32

AABB :: struct
{
	min: Vector2,
	max: Vector2
}

Color :: rl.Color
