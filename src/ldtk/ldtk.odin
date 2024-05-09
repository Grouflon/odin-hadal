package ldtk

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:log"
import "hadal:tools"

LdtkData :: struct
{
	levels: [dynamic]^LdtkLevel
}

LdtkLevel :: struct
{
	identifier: string,
	position:[2]f32,
	size:[2]f32,
	entities: [dynamic]^LdtkEntity,
	customVariables: map[string]LdtkVariable,
}

LdtkEntity :: struct
{
	identifier: string,
	position:[2]f32,
	id: i32,
	width: f32,
	height: f32,
	customVariables: map[string]LdtkVariable,
}

LdtkUnion :: union{i32, f32, string, bool}

LdtkVariable :: struct
{
	value: LdtkUnion
}


load_level :: proc(path:string) -> ^LdtkData
{
	data: json.Value = tools.load_json(path)
	defer json.destroy_value(data)

	assert(data != nil, "error")
	ldtk:= new(LdtkData)
	
	root := data.(json.Object)
	levels := root["levels"].(json.Array)
	for lvl in levels
	{
		ldtk_level: = new(LdtkLevel)
		append(&ldtk.levels, ldtk_level)
		level: = lvl.(json.Object)
		layerInstances: = level["layerInstances"].(json.Array)
		ldtk_level.identifier = strings.clone(level["identifier"].(json.String))
		_worldX: = level["worldX"].(json.Float)
		_worldY: = level["worldY"].(json.Float)
		_worldW: = level["pxWid"].(json.Float)
		_worldH: = level["pxHei"].(json.Float)
		ldtk_level.position = {f32(_worldX), f32(_worldY)}
		ldtk_level.size = {f32(_worldW), f32(_worldH)}

		fieldInstances: = level["fieldInstances"].(json.Array)

		for fieldInstance in fieldInstances
		{
			notFound, name, variable: = parse_custom_variable(fieldInstance.(json.Object))
			if (!notFound)
			{
				ldtk_level.customVariables[name] = variable
			}
		}

		for layerInstance in layerInstances
		{
			entityInstances:= layerInstance.(json.Object)["entityInstances"].(json.Array)

			for entityInstance in entityInstances
			{
				ldtk_entity: = parse_entity(entityInstance.(json.Object))
				append(&ldtk_level.entities, ldtk_entity)
			}
		}
	}
	return ldtk
}

parse_entity :: proc(_entityInstanceObj: json.Object) -> ^LdtkEntity
{
	ldtk_entity: = new(LdtkEntity)
	ldtk_entity.identifier = strings.clone(_entityInstanceObj["__identifier"].(json.String))
	ldtk_entity.id = i32(_entityInstanceObj["defUid"].(json.Float))
	position: = _entityInstanceObj["px"].(json.Array)
	ldtk_entity.position = {f32(position[0].(json.Float)), f32(position[1].(json.Float))}
	ldtk_entity.width = f32(_entityInstanceObj["width"].(json.Float))
	ldtk_entity.height = f32(_entityInstanceObj["height"].(json.Float))

	fieldInstances: = _entityInstanceObj["fieldInstances"].(json.Array)

	for fieldInstance in fieldInstances
	{
		notFound, name, variable: = parse_custom_variable(fieldInstance.(json.Object))
		if (!notFound)
		{
			ldtk_entity.customVariables[name] = variable
		}
	}

	return ldtk_entity
}

parse_custom_variable :: proc(_fieldInstance: json.Object) -> (notFound: bool, identifier: string, ldtkVariable: LdtkVariable)
{
	_ldtkVariable: LdtkVariable
	_identifier: = _fieldInstance["__identifier"].(json.String)
	_type: = _fieldInstance["__type"].(json.String)

	_value: = _fieldInstance["__value"]

	#partial switch _ in _value
	{
		case json.Null:
			return true, _identifier, _ldtkVariable
	}

	switch _type
	{
		case "Int":
		{
			_ldtkVariable.value = i32(_value.(json.Float))
		}
		case "Float":
		{
			_ldtkVariable.value = f32(_value.(json.Float))
		}
		case "String":
		{
			_ldtkVariable.value = strings.clone(_value.(json.String))
		}
		case "Boolean":
		{
			_ldtkVariable.value = _value.(json.Boolean)
		}
		case "Color":
		{
			_ldtkVariable.value = strings.clone(_value.(json.String))
		}
		case:
		{
			return true, _identifier, _ldtkVariable
		}
	}

	return false, strings.clone(_identifier), _ldtkVariable
}

free_data :: proc(using _level_data: ^LdtkData)
{
	for _i: = len(levels) - 1; _i >= 0; _i -= 1
	{
		free_level(levels[_i])
	}
	delete(levels)
	free(_level_data)
}

free_level :: proc(using _level: ^LdtkLevel)
{

	for customVariable in customVariables {
		free_custom_variable(customVariables[customVariable])
		delete(customVariable)
	}
	delete(customVariables)

	free_entities(entities)
	delete(identifier)
	free(_level)
}

free_entities :: proc(_entities: [dynamic]^LdtkEntity)
{
	for _i: = len(_entities) - 1; _i >= 0; _i -= 1
	{
		free_entity(_entities[_i])
	}
	delete(_entities)
}

free_entity :: proc(using _entity: ^LdtkEntity)
{
	for customVariable in customVariables {
		free_custom_variable(customVariables[customVariable])
		delete(customVariable)
	}

	delete(customVariables)
	delete(identifier)

	free(_entity)
}

free_custom_variable :: proc(variable: LdtkVariable)
{
	value: = variable.value
	#partial switch _ in value
	{
		case string:
		{
			delete_string(value.(string))
		}
	}
}