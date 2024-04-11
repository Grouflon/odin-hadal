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
	entities: [dynamic]^LdtkEntity
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

LdtkVariable :: struct
{
	value: union{i32, f32, string, bool}
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
		ldtk_level.identifier = level["identifier"].(json.String)
		_worldX: = level["worldX"].(json.Float)
		_worldY: = level["worldY"].(json.Float)
		ldtk_level.position = {f32(_worldX), f32(_worldY)}

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
	ldtk_entity.identifier = _entityInstanceObj["__identifier"].(json.String)
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
			_ldtkVariable.value = _value.(json.String)
		}
		case "Boolean":
		{
			_ldtkVariable.value = _value.(json.Boolean)
		}
		case "Color":
		{
			_ldtkVariable.value = _value.(json.String)
		}
		case:
		{
			return true, _identifier, _ldtkVariable
		}
	}

	return false, _identifier, _ldtkVariable
}

free_level :: proc(_level_data: ^LdtkData)
{
	for _i: = len(_level_data.levels) - 1; _i >= 0; _i -= 1
	{
		free_entities(_level_data.levels[_i].entities)
		free(_level_data.levels[_i])
	}
	delete(_level_data.levels)
	free(_level_data)
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
	delete(customVariables)
	free(_entity)
}