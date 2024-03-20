package main
import rl "vendor:raylib"
/*
Mine :: struct
{
	using entity : Entity,
	radius: f32,
	timer:f32,
	time:f32,
	isstart:bool,
	isactived:bool,
	isboom:bool,
	hasboom:bool,
	explosion_radius:f32,
}

mine_expode :: proc(mine : ^Mine)
{
	using mine
	
}

mine_update :: proc(_entity : ^Entity)
{
	using mine := cast(^Mine)_entity

	if (isboom)
	{
		time+=1/60
		if(time>1)
		{
			isboom = true
			hasboom = false
		}
	}

	if (isstart)
	{

	}

	if (isactived)
	{
		time+=1/60
		if (time>timer)
		{
			mine_expode(mine)
		}
	}
}

mine_draw :: proc(_entity : ^Entity)
{
	using mine := cast(^Mine)_entity
	
	x, y : i32 = i32(position.x), i32(position.y)

	if (hasboom)
	{

	}
	else if (isboom)
	{
		rl.DrawPixel(x, y, rl.GREEN)
		rl.DrawCircle(x, y, explosion_radius, rl.RED)
	}
	else if (isactived)
	{
		rl.DrawPixel(x, y, rl.RED)
	}
	else
	{
		rl.DrawPixel(x, y, rl.GREEN)
	}
}

mine_make :: proc(_position : rl.Vector2) -> ^Mine
{
	mine := new(Mine)
	mine.position = _position
	mine.radius = 1
	mine.timer = 0.2
	mine.time = 0
	mine.explosion_radius = 5

	mine.update = mine_update
	mine.draw = mine_draw

	return mine
}

*/