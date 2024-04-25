package game

import "core:reflect"

Delegate :: struct($ProcType: typeid)
{
	procedure: ProcType,
	userdata: rawptr,
}

Signal :: struct($ProcType: typeid)
{
	delegates: [dynamic]Delegate(ProcType),
}

signal_initialize :: proc(_signal: ^Signal($ProcType))
{
	_signal.delegates = make([dynamic]Delegate(ProcType))
}

signal_shutdown :: proc(_signal: ^Signal($ProcType))
{
	delete(_signal.delegates)
}

signal_register_delegate :: proc(_signal: ^Signal($ProcType), _proc: ProcType, _userdata: rawptr = nil)
{
	assert(reflect.type_kind(ProcType) == .Procedure)
	assert(_signal != nil)
	assert(_proc != nil)
	delegate: Delegate(ProcType) = {
		procedure = _proc,
		userdata = _userdata,
	}
	append(&_signal.delegates, delegate)
}

signal_unregister_delegate :: proc(_signal: ^Signal($ProcType), _proc: ProcType, _userdata: rawptr = nil)
{
	assert(reflect.type_kind(ProcType) == .Procedure)
	assert(_signal != nil)
	assert(_proc != nil)

	for i in 0..<len(_signal.delegates)
	{
		delegate: = _signal.delegates[i]
		if (delegate.procedure == _proc && delegate.userdata == _userdata)
		{
			ordered_remove(&_signal.delegates, i)
			return
		}
	}

	assert(false, "Could not unregister delegate from signal")
}

signal_broadcast :: proc {
	signal_broadcast_0arg,
	signal_broadcast_1arg,
	signal_broadcast_2arg,
	signal_broadcast_3arg,
	signal_broadcast_4arg,
	signal_broadcast_5arg,
	signal_broadcast_6arg,
	signal_broadcast_7arg,
	signal_broadcast_8arg,
}

signal_broadcast_0arg :: proc(_signal: ^Signal($ProcType))
{
	for i: = len(_signal.delegates) - 1; i >=0; i -= 1
	{
		delegate: = _signal.delegates[i]
		delegate.procedure(delegate.userdata)
	}
}

signal_broadcast_1arg :: proc(_signal: ^Signal($ProcType), _arg1: $Type1)
{
	for i: = len(_signal.delegates) - 1; i >=0; i -= 1
	{
		delegate: = _signal.delegates[i]
		delegate.procedure(delegate.userdata, _arg1)
	}
}

signal_broadcast_2arg :: proc(_signal: ^Signal($ProcType), _arg1: $Type1, _arg2: $Type2)
{
	for i: = len(_signal.delegates) - 1; i >=0; i -= 1
	{
		delegate: = _signal.delegates[i]
		delegate.procedure(delegate.userdata, _arg1, _arg2)
	}
}

signal_broadcast_3arg :: proc(_signal: ^Signal($ProcType), _arg1: $Type1, _arg2: $Type2, _arg3: $Type3)
{
	for i: = len(_signal.delegates) - 1; i >=0; i -= 1
	{
		delegate: = _signal.delegates[i]
		delegate.procedure(delegate.userdata, _arg1, _arg2, _arg3)
	}
}

signal_broadcast_4arg :: proc(_signal: ^Signal($ProcType), _arg1: $Type1, _arg2: $Type2, _arg3: $Type3, _arg4: $Type4)
{
	for i: = len(_signal.delegates) - 1; i >=0; i -= 1
	{
		delegate: = _signal.delegates[i]
		delegate.procedure(delegate.userdata, _arg1, _arg2, _arg3, _arg4)
	}
}

signal_broadcast_5arg :: proc(_signal: ^Signal($ProcType), _arg1: $Type1, _arg2: $Type2, _arg3: $Type3, _arg4: $Type4, _arg5: $Type5)
{
	for i: = len(_signal.delegates) - 1; i >=0; i -= 1
	{
		delegate: = _signal.delegates[i]
		delegate.procedure(delegate.userdata, _arg1, _arg2, _arg3, _arg4, _arg5)
	}
}

signal_broadcast_6arg :: proc(_signal: ^Signal($ProcType), _arg1: $Type1, _arg2: $Type2, _arg3: $Type3, _arg4: $Type4, _arg5: $Type5, _arg6: $Type6)
{
	for i: = len(_signal.delegates) - 1; i >=0; i -= 1
	{
		delegate: = _signal.delegates[i]
		delegate.procedure(delegate.userdata, _arg1, _arg2, _arg3, _arg4, _arg5, _arg6)
	}
}

signal_broadcast_7arg :: proc(_signal: ^Signal($ProcType), _arg1: $Type1, _arg2: $Type2, _arg3: $Type3, _arg4: $Type4, _arg5: $Type5, _arg6: $Type6, _arg7: $Type7)
{
	for i: = len(_signal.delegates) - 1; i >=0; i -= 1
	{
		delegate: = _signal.delegates[i]
		delegate.procedure(delegate.userdata, _arg1, _arg2, _arg3, _arg4, _arg5, _arg6, _arg7)
	}
}

signal_broadcast_8arg :: proc(_signal: ^Signal($ProcType), _arg1: $Type1, _arg2: $Type2, _arg3: $Type3, _arg4: $Type4, _arg5: $Type5, _arg6: $Type6, _arg7: $Type7, _arg8: $Type8)
{
	for i: = len(_signal.delegates) - 1; i >=0; i -= 1
	{
		delegate: = _signal.delegates[i]
		delegate.procedure(delegate.userdata, _arg1, _arg2, _arg3, _arg4, _arg5, _arg6, _arg7, _arg8)
	}
}
