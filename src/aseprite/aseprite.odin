package aseprite

import "core:encoding/json"
import "core:path/filepath"
import "core:log"
import "core:os"
import "core:reflect"
import "core:strings"
import "core:strconv"

AsepriteData :: struct
{
	version: string,

	image_path: string,
	image_format: ImageFormat,
	image_size: [2]i32,
	scale: i32,

	frames: []Frame,
	frame_tags: map[string]FrameTag,
	layers: []Layer,
}

Frame :: struct
{
	name: string,
	position: [2]i32,
	size: [2]i32,
	duration: i32,
	rotated: bool,
	trimmed: bool,
	sprite_source_position: [2]i32,
	sprite_source_size: [2]i32,
	source_size: [2]i32,
}

FrameTag :: struct
{
	from: i32,
	to: i32,
	repeat: i32, // 0 means loop
	direction: Direction,
	color: [4]u8,
}

Layer :: struct
{
	name: string,
	opacity: f32,
	blend_mode: BlendMode,
}

ImageFormat :: enum
{
	RGBA8888,
	I8,	
}

BlendMode :: enum
{
	normal,
}

Direction :: enum
{
	forward,
	backward
}

load_data :: proc { load_data_from_path, load_data_from_bytes }

load_data_from_path :: proc(_json_path: string) -> ^AsepriteData
{
	_data, _ok := os.read_entire_file_from_filename(_json_path)
	if !_ok {
		log.errorf("Faile to load file \"%s\"", _json_path)
		return nil
	}
	defer delete(_data) // Free the memory at the end

	_directory, _file: = filepath.split(_json_path)
	return load_data_from_bytes(_directory, _data)
}

load_data_from_bytes :: proc(_root_path: string, _data: []byte) -> ^AsepriteData
{
	assert(os.exists(_root_path))
	{
		_file_info, _err: = os.stat(_root_path, context.temp_allocator)
		assert(_err == 0 && _file_info.is_dir)
	}

	_read_box :: proc(_value: ^json.Value, _position: ^[2]i32, _size: ^[2]i32)
	{
		if _value == nil { return }
		_object: = _value.(json.Object)
		if _object == nil { return }

		if _position != nil
		{
			_x_value: = _object["x"]
			if (_x_value != nil)
			{
				_position[0] = i32(_x_value.(json.Float))
			}

			_y_value: = _object["y"]
			if (_y_value != nil)
			{
				_position[1] = i32(_y_value.(json.Float))
			}
		}

		if _size != nil
		{
			_w_value: = _object["w"]
			if (_w_value != nil)
			{
				_size[0] = i32(_w_value.(json.Float))
			}

			_h_value: = _object["h"]
			if (_h_value != nil)
			{
				_size[1] = i32(_h_value.(json.Float))
			}
		}
	}

	_read_frame :: proc(_object: ^json.Object, _frame: ^Frame, _name: string)
	{
		_frame.name = strings.clone(_name)
		_read_box(&_object["frame"], &_frame.position, &_frame.size)
		_frame.duration = i32(_object["duration"].(json.Float))
		_frame.rotated = _object["rotated"].(json.Boolean)
		_frame.trimmed = _object["trimmed"].(json.Boolean)
		_read_box(&_object["spriteSourceSize"], &_frame.sprite_source_position, &_frame.sprite_source_size)
		_read_box(&_object["sourceSize"], nil, &_frame.source_size)
	}

	_json_data, _err := json.parse(_data)
	if _err != .None {
		log.error("Failed to parse json data")
		log.errorf("Error:", _err)
		return nil
	}
	defer json.destroy_value(_json_data)

	_data: = new(AsepriteData)

	_root: = _json_data.(json.Object)

	// Frames
	_frames: = _root["frames"]
	if _frames != nil
	{

		#partial switch _value in _frames
		{
			case json.Object:
			{
				_frames_object: = _value
				_data.frames = make([]Frame, len(_frames_object))

				_i: = 0
				for _name, _frame_value in _frames_object
				{
					_frame_object: = _frame_value.(json.Object)
					_frame: ^Frame = &_data.frames[_i]

					_read_frame(&_frame_object, _frame, _name)

					_i += 1
				}
			}

			case json.Array:
				_frames_array: = _value
				_data.frames = make([]Frame, len(_frames_array))

				for _frame_value, _i in _frames_array
				{
					_frame_object: = _frame_value.(json.Object)
					_frame: ^Frame = &_data.frames[_i]
					
					_read_frame(&_frame_object, _frame, _frame_object["filename"].(json.String))
				}
			case:
		}
	}

	// Meta
	_meta: = _root["meta"].(json.Object)
	if _meta != nil
	{
		_data.version = strings.clone(_meta["version"].(json.String))

		_data.image_path = filepath.join({_root_path, _meta["image"].(json.String)})

		{
			_value, _ok: = reflect.enum_from_name(ImageFormat, _meta["format"].(json.String))
			_data.image_format = _ok ? _value : .RGBA8888
		}

		_read_box(&_meta["size"], nil, &_data.image_size)

		_data.scale = i32(strconv.atoi(_meta["scale"].(json.String)))

		// Tags
		_frame_tags_array: = _meta["frameTags"].(json.Array)
		for _frame_tag_value in _frame_tags_array
		{
			_frame_tag_object: = _frame_tag_value.(json.Object)
			_frame_tag: FrameTag

			_frame_tag.from = i32(_frame_tag_object["from"].(json.Float))
			_frame_tag.to = i32(_frame_tag_object["to"].(json.Float))

			_repeat_value: = _frame_tag_object["repeat"]
			_frame_tag.repeat = _repeat_value != nil ? i32(strconv.atoi(_repeat_value.(json.String))) : 0

			{
				_value, _ok: = reflect.enum_from_name(Direction, _frame_tag_object["direction"].(json.String))
				_frame_tag.direction = _ok ? _value : .forward
			}

			{
				_color, _ok: = strconv.parse_u64(_frame_tag_object["color"].(json.String))
				if _ok
				{
					_frame_tag.color[3] = u8(_color)
					_frame_tag.color[2] = u8(_color >> 8)
					_frame_tag.color[1] = u8(_color >> 16)
					_frame_tag.color[0] = u8(_color >> 24)
				}
			}

			_data.frame_tags[strings.clone(_frame_tag_object["name"].(json.String))] = _frame_tag 
		}

		// Layers
		_layers_array: = _meta["layers"].(json.Array)
		_data.layers = make([]Layer, len(_layers_array))
		for _layer_value, _i in _layers_array
		{
			_layer_object: = _layer_value.(json.Object)
			_layer: ^Layer = &_data.layers[_i]

			_layer.name = strings.clone(_layer_object["name"].(json.String))
			_layer.opacity = f32(_layer_object["opacity"].(json.Float)) / 255.0

			{
				_value, _ok: = reflect.enum_from_name(BlendMode, _layer_object["blendMode"].(json.String))
				_layer.blend_mode = _ok ? _value : .normal
			}
		}

		// TODO: Slices
	}


	return _data
}

free_data :: proc(_data: ^AsepriteData)
{
	assert(_data != nil)

	delete(_data.version)
	delete(_data.image_path)
	for key, frame_tag in _data.frame_tags
	{
		delete(key)
	}
	delete(_data.frame_tags)
	
	for _layer in _data.layers
	{
		delete(_layer.name)
	}
	delete(_data.layers)

	for _frame in _data.frames
	{
		delete(_frame.name)
	}
	delete(_data.frames)
	free(_data)
}