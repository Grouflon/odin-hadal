package game

import rl "vendor:raylib"
import "core:math"

Spritesheet :: struct
{
    texture : rl.Texture2D,
    columns : int,
    rows : int,
    cell_width : int,
    cell_height : int,
}

build_spritesheet :: proc (_texture : rl.Texture2D, _columns : int, _rows : int) -> Spritesheet
{
    return Spritesheet{
        texture = _texture,
        columns = _columns,
        rows = _rows,
        cell_width = int(_texture.width) / _columns,
        cell_height = int(_texture.height) / _rows,
    }
}

AnimFrame :: struct
{
    index : int,
    duration : int,
}

Animation :: struct
{
    spritesheet : ^Spritesheet,
    loop : bool,
    frames : [dynamic]AnimFrame,
}

make_animation :: proc(_spritesheet: ^Spritesheet, _loop: bool, _frames: []AnimFrame) -> ^Animation
{
    _animation: = new(Animation)
    _animation.spritesheet = _spritesheet
    _animation.loop = _loop
    _animation.frames = make([dynamic]AnimFrame)
    for _frame in _frames
    {
        append(&_animation.frames, _frame)
    }
    return _animation
}

delete_animation :: proc(_animation: ^Animation)
{
    assert(_animation != nil)

    delete(_animation.frames)
    free(_animation)
}

AnimationPlayer :: struct
{
    fps : f32,

    _current_animation : ^Animation,
    _total_animation_frames : int,
    _frame : f32,
}

animation_player_play :: proc(_player : ^AnimationPlayer, _animation : ^Animation)
{
    if _player._current_animation == _animation { return }

    _player._current_animation = _animation
    _player._frame = 0.0
    _player._total_animation_frames = 0

    if _player._current_animation != nil
    {
        for frame in _player._current_animation.frames
        {
            _player._total_animation_frames += frame.duration
        }
    }
}

animation_player_update :: proc(_player : ^AnimationPlayer, _dt : f32)
{
    if _player._total_animation_frames <= 0 { return }

    total_frames : f32 = f32(_player._total_animation_frames)
    if total_frames <= 0 { return }

    _player._frame += _player.fps * _dt
    if (_player._current_animation.loop)
    {
        for _player._frame > total_frames
        {
            _player._frame -= total_frames;
        }
    }
    else
    {
        _player._frame = math.max(total_frames - 1.0, _player._frame)
    }
}

animation_player_draw:: proc(_player : ^AnimationPlayer, _position : rl.Vector2, _flip_x : bool = false, _flip_y : bool = false, _tint : rl.Color = rl.WHITE)
{
    if _player._total_animation_frames <= 0 { return }

    frame_index := int(math.floor(_player._frame))

    sprite_index := -1
    current_frame_index := 0
    for frame in _player._current_animation.frames
    {
        if frame_index >= current_frame_index && frame_index < current_frame_index + frame.duration
        {
            sprite_index = frame.index
            break
        }
        current_frame_index += frame.duration
    }
    assert(sprite_index >= 0)

    spritesheet := _player._current_animation.spritesheet
    x := sprite_index % spritesheet.columns
    y := sprite_index / spritesheet.columns
    rl.DrawTextureRec(
        spritesheet.texture,
        {
            f32(x * spritesheet.cell_width),
            f32(y * spritesheet.cell_height),
            (_flip_x ? -1.0 : 1.0) * f32(spritesheet.cell_width),
            (_flip_y ? -1.0 : 1.0) * f32(spritesheet.cell_height)
        },
        _position,
        _tint
    );
}