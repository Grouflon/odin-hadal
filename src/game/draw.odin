package game

import "core:math"
import rl "vendor:raylib"

dash_stroke_shader : rl.Shader
dash_stroke_shader_uniforms : [3]rl.ShaderLocationIndex

draw_init :: proc()
{
	dash_stroke_shader = rl.LoadShader("data/shaders/dashed_line.vert", "data/shaders/dashed_line.frag")
	dash_stroke_shader_uniforms[0] = rl.GetShaderLocation(dash_stroke_shader, "points")
	dash_stroke_shader_uniforms[1] = rl.GetShaderLocation(dash_stroke_shader, "dashSize")
	dash_stroke_shader_uniforms[2] = rl.GetShaderLocation(dash_stroke_shader, "dashOffset")
}

draw_shutdown :: proc()
{
	rl.UnloadShader(dash_stroke_shader)
}

draw_dashed_line :: proc(_startPos, _endPos: Vector2, _color: Color, _dash_size: f32 = 4.0, _dash_offset: f32 = 0.0)
{
	rl.BeginShaderMode(dash_stroke_shader)
	defer rl.EndShaderMode()

	points: [2]Vector2 = {_startPos, _endPos}
	dash_size: = _dash_size
	dash_offset: = _dash_offset

	rl.SetShaderValueV(dash_stroke_shader, dash_stroke_shader_uniforms[0], raw_data(&points), rl.ShaderUniformDataType.VEC2, 2)
	rl.SetShaderValue(dash_stroke_shader, dash_stroke_shader_uniforms[1], &dash_size, rl.ShaderUniformDataType.FLOAT)
	rl.SetShaderValue(dash_stroke_shader, dash_stroke_shader_uniforms[2], &dash_offset, rl.ShaderUniformDataType.FLOAT)

	rl.DrawLineV(_startPos, _endPos, _color)
}