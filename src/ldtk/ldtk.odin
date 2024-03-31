package ldtk

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:log"

LdtkData :: struct
{
	levels: [dynamic]^LdtkLevel
}
LdtkLevel :: struct
{
	identifier: string,
	entities: [dynamic]LdtkEntity
}

LdtkEntity::struct
{
	identifier: string,
	position:[2]f32,
	id: i32,
	width: f32,
	height: f32,
}

load_json::proc(path:string) -> json.Value
{
	data, ok := os.read_entire_file_from_filename(path)
	if !ok {
		log.errorf("Faile to load file \"%s\"", path)
		return nil
	}
	defer delete(data) // Free the memory at the end
	
	// Parse the json file.
	json_data, err := json.parse(data)
	if err != .None {
		log.errorf("Faile to parse json file \"%s\"", path)
		log.errorf("Error:", err)
		return nil
	}

	return json_data;
}


load_level::proc(path:string) -> ^LdtkData
{
	data: json.Value = load_json(path)
	defer json.destroy_value(data)

	assert(data != nil, "error")
	ldtk:= new(LdtkData)
	
	root := data.(json.Object)
	levels := root["levels"].(json.Array)
	for lvl in levels
	{
		ldtk_level: = new(LdtkLevel)
		append(&ldtk.levels, ldtk_level)
		layerInstances := lvl.(json.Object)["layerInstances"].(json.Array)
		ldtk_level.identifier = lvl.(json.Object)["identifier"].(json.String)

		for layerInstance in layerInstances
		{
			entityInstances:= layerInstance.(json.Object)["entityInstances"].(json.Array)

			for entityInstance in entityInstances
			{
				entityInstanceObj := entityInstance.(json.Object)
				ldtk_entity:LdtkEntity
				assert(entityInstanceObj != nil, "hooho")
				ldtk_entity.identifier = entityInstanceObj["__identifier"].(json.String)
				ldtk_entity.id = i32(entityInstanceObj["defUid"].(json.Float))
				position := entityInstanceObj["px"].(json.Array)
				ldtk_entity.position = {f32(position[0].(json.Float)), f32(position[1].(json.Float))}
				ldtk_entity.width = f32(entityInstanceObj["width"].(json.Float))
				ldtk_entity.height = f32(entityInstanceObj["height"].(json.Float))

				append(&ldtk_level.entities, ldtk_entity)
			}
		}
	}

	return ldtk
}

free_level :: proc(_level_data : ^LdtkData)
{
	for _i: = len(_level_data.levels) - 1; _i >= 0; _i -= 1
	{
		delete(_level_data.levels[_i].entities)
		free(_level_data.levels[_i])
	}
	delete(_level_data.levels)
	free(_level_data)
}