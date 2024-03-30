package game

import rl "vendor:raylib"
import "core:fmt"
import "core:log"
import "core:math"
import "core:os"
import "core:strings"
import "hadal:aseprite"

AnimationSet :: struct
{
    texture: rl.Texture2D,
    frames: []AnimationFrame,
    animations: []Animation,
    name_to_animation: map[string]i32
}

AnimationFrame :: struct
{
    position: [2]i32,
    size: [2]i32,
    duration_in_ms: i32,
}

Animation :: struct
{
    name: string,
    start_frame: i32,
    end_frame: i32,
    duration_in_ms: i32,
    repeat_count: i32, // 0 means loop
}

make_animation_set :: proc(_aseprite_data: ^aseprite.AsepriteData) -> ^AnimationSet
{
    assert(_aseprite_data != nil)

    _animation_set: = new(AnimationSet)
    if os.exists(_aseprite_data.image_path)
    {
        _texture_path: = strings.clone_to_cstring(_aseprite_data.image_path, context.temp_allocator)
        _animation_set.texture = rl.LoadTexture(_texture_path)
    }
    else
    {
        log.errorf("Can't load spritesheet \"%s\"", _aseprite_data.image_path)
    }

    _animation_set.frames = make([]AnimationFrame, len(_aseprite_data.frames))
    for _frame, _i in _aseprite_data.frames
    {
        _animation_set.frames[_i].position = _frame.position
        _animation_set.frames[_i].size = _frame.size
        _animation_set.frames[_i].duration_in_ms = _frame.duration
    }

    _animation_set.animations = make([]Animation, len(_aseprite_data.frame_tags))
    _animation_set.name_to_animation = make(map[string]i32, len(_aseprite_data.frame_tags))
    _i: i32 = 0
    for _name, _frame_tag in _aseprite_data.frame_tags
    {
        _animation: = &_animation_set.animations[_i]
        _animation_set.name_to_animation[strings.clone(_name)] = _i

        _animation.name = strings.clone(_name)
        _animation.start_frame = _frame_tag.from
        _animation.end_frame = _frame_tag.to
        _animation.duration_in_ms = 0
        for _j: i32 = 0; _j <= (_animation.end_frame - _animation.start_frame); _j += 1
        {
            _animation.duration_in_ms += _animation_set.frames[_animation.start_frame + _j].duration_in_ms
        }
        _i += 1
    }

    return _animation_set
}

delete_animation_set :: proc(_animation_set: ^AnimationSet)
{
    rl.UnloadTexture(_animation_set.texture)
    delete(_animation_set.frames)
    for _animation in _animation_set.animations
    {
        delete(_animation.name)
    }
    for _name, _ in _animation_set.name_to_animation
    {
        delete(_name)
    }
    delete(_animation_set.animations)
    delete(_animation_set.name_to_animation)
    free(_animation_set)
}

AnimationPlayer :: struct
{
    play_rate : f32,

    // private
    animation_set: ^AnimationSet,
    current_animation: i32,

    current_frame: i32,
    current_time_ms: f32,
    current_repeat_count: i32,
    is_playing: bool,
}

AnimationManager :: struct
{
    players: [dynamic]^AnimationPlayer
}

animation_manager_initialize :: proc(using _manager: ^AnimationManager)
{
    assert(_manager != nil)
    players = make([dynamic]^AnimationPlayer)
}

animation_manager_shutdown :: proc(using _manager: ^AnimationManager)
{
    assert(_manager != nil)
    assert(len(players) == 0, "All animation players must be destroyed by their creators")
    delete(players)
}

animation_mananger_register_player :: proc(using _manager: ^AnimationManager, _player: ^AnimationPlayer)
{
    assert(_manager != nil)
    assert(_player != nil)
    assert(find(&players, _player) < 0, "Player already registered")

    append(&players, _player)
}

animation_mananger_unregister_player :: proc(using _manager: ^AnimationManager, _player: ^AnimationPlayer)
{
    assert(_manager != nil)
    assert(_player != nil)
    _index := find(&players, _player)
    assert(_index >= 0, "Trying to unregistered a non registered Player")

    unordered_remove(&players, _index)
}

animation_manager_update :: proc(using _manager: ^AnimationManager, _dt: f32)
{
    assert(_manager != nil)
    for _player in players
    {
        animation_player_update(_player, _dt)
    }
}

create_animation_player :: proc() -> ^AnimationPlayer
{
    _player: = new(AnimationPlayer)
    _player.play_rate = 1.0
    _player.current_frame = -1
    _player.current_animation = -1

    animation_mananger_register_player(&game().animation_manager, _player)
    return _player
}

destroy_animation_player :: proc(_player: ^AnimationPlayer)
{
    assert(_player != nil)

    animation_mananger_unregister_player(&game().animation_manager, _player)
    free(_player)
}

animation_player_play :: proc(using _player: ^AnimationPlayer, _animation_set: ^AnimationSet, _animation_name: string)
{
    assert(_player != nil)
    assert(_animation_set != nil)

    animation_set = _animation_set
    if !(_animation_name in animation_set.name_to_animation) { return }
    _wanted_animation, ok: = animation_set.name_to_animation[_animation_name]
    if current_animation == _wanted_animation { return }

    animation_player_stop(_player)

    current_animation = _wanted_animation
    current_time_ms = 0.0
    current_frame = -1
    current_repeat_count = 0
    is_playing = true

    animation_player_update(_player, 0.0)
}

animation_player_stop :: proc(using _player: ^AnimationPlayer)
{
    if is_playing
    {
        animation_player_update(_player, 0.0) // Note: maybe we need a stop requested flag instead of that
        is_playing = false
    }
}

animation_player_update :: proc(using _player : ^AnimationPlayer, _dt : f32)
{
    assert(_player != nil)

    if !is_playing { return }
    if current_animation < 0 { return }
    _animation: = animation_set.animations[current_animation]

    // Update loops
    for current_time_ms > f32(_animation.duration_in_ms)
    {
        current_time_ms -= f32(_animation.duration_in_ms)
        current_repeat_count += 1
        if _animation.repeat_count > 0 && current_repeat_count >= _animation.repeat_count
        {
            current_time_ms = f32(_animation.duration_in_ms)
            is_playing = false
        }
    }

    // Update frame
    _duration: i32 = 0 
    _time_in_ms: i32 = floor_to_int(current_time_ms)
    for _i: = _animation.start_frame; _i <= _animation.end_frame; _i+=1
    {
        _frame: = &animation_set.frames[_i]
        if _time_in_ms <= _duration + _frame.duration_in_ms
        {
            current_frame = _i
            break
        }
        _duration += _frame.duration_in_ms
    }

    // Update time
    if (is_playing)
    {
        current_time_ms += _dt * 1000
    }
}

animation_player_draw:: proc(using _player : ^AnimationPlayer, _position : Vector2, _flip_x : bool = false, _flip_y : bool = false, _tint : Color = rl.WHITE)
{
    assert(_player != nil)

    if (animation_set == nil) { return }
    if (animation_set.texture.id == 0) { return }
    if (current_frame < 0 || current_frame >= i32(len(animation_set.frames))) { return }

    _frame: = &animation_set.frames[_player.current_frame]

    rl.DrawTextureRec(
        animation_set.texture,
        {
            f32(_frame.position[0]),
            f32(_frame.position[1]),
            (_flip_x ? -1.0 : 1.0) * f32(_frame.size[0]),
            (_flip_y ? -1.0 : 1.0) * f32(_frame.size[1])
        },
        _position,
        _tint
    );
}