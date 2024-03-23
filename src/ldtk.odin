package main
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:log"

LdtkData :: struct
{
	entities: [dynamic]LdtkEntity
}

LdtkEntity::struct
{
	identifier: string,
	position:Vector2,
	id: i32
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
		layerInstances := lvl.(json.Object)["layerInstances"].(json.Array)
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
				position := entityInstanceObj["__grid"].(json.Array)
				ldtk_entity.position = Vector2{f32(position[0].(json.Float)), f32(position[1].(json.Float))}

				append(&ldtk.entities, ldtk_entity)
			}
		}
	}
	return ldtk
}

free_level :: proc(_level_data : ^LdtkData)
{
	delete(_level_data.entities)
	free(_level_data)
}