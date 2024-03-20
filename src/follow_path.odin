package main

agent_follow_path :: proc(_agent: ^Agent, _path: []Vector2, _speed: f32)
{
	if (len(_path) == 0)
	{
		return
	}

	FollowPathData :: struct
	{
		agent: ^Agent,
		speed: f32,
		path: [dynamic]Vector2,

		walked_distance: f32,
		current_node: i32,
	}

	_data: = new(FollowPathData)
	_data.agent = _agent
	_data.speed = _speed
	copy_array(&_data.path, _path)
	inject_at(&_data.path, 0, _agent.position)

	action_start(
		_data,
		proc(_action: ^Action)
		{
			// Start
			_data: = cast(^FollowPathData)_action.payload

			_data.walked_distance = 0
			_data.current_node = 0
		},
		proc(_action: ^Action)
		{
			// Update
			_data: = cast(^FollowPathData)_action.payload

			
		},
		proc(_action: ^Action)
		{
			// Stop
			_data: = cast(^FollowPathData)_action.payload
			delete(_data.path)
			free(_action.payload)
		},
	)

	// local _dist=0
    //   for _i=1,#_path-1 do
    //     local _start, _end = _path[_i], _path[_i+1]
    //     assert(_start ~= nil)
    //     assert(_end ~= nil)
    //     local _traj=_end-_start
    //     local _len=vec2_len(_traj)
    //     local _dir=vec2_normalized(_traj)
    //     while _dist < _len do
    //       _agent.pos=_start+_dir*_dist
    //       yield()
    //       _dist+=_speed
    //     end
    //     _dist-=_len
    //   end
    //   _agent.pos=_path[#_path]
}