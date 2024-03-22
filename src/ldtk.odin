package main
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"

ldtk::struct
{
	entities: [dynamic]ldtk_entity
}

ldtk_entity::struct
{
	identifier: string,
	position:Vector2,
	id: i32
}

load_json::proc(path:string) -> json.Value
{
	data, ok := os.read_entire_file_from_filename(path)
	if !ok {
		fmt.eprintln("Failed to load the file!")
		return nil
	}
	defer delete(data) // Free the memory at the end
	
	// Parse the json file.
	json_data, err := json.parse(data)
	if err != .None {
		fmt.eprintln("Failed to parse the json file.")
		fmt.eprintln("Error:", err)
		return nil
	}

	return json_data;
}


load_ldtk::proc(path:string) -> ldtk
{
	data := load_json(path)
	assert(data != nil, "error")
	ldtk:ldtk
	
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
				ldtk_entity:ldtk_entity
				assert(entityInstanceObj != nil, "hooho")
				ldtk_entity.identifier = entityInstanceObj["__identifier"].(json.String)
				ldtk_entity.id = i32(entityInstanceObj["defUid"].(json.Float))
				position := entityInstanceObj["__grid"].(json.Array)
				ldtk_entity.position = Vector2{f32(position[0].(json.Float)), f32(position[1].(json.Float))}

				append(&ldtk.entities, ldtk_entity)
			}
		}
	}
	defer json.destroy_value(data)
	return ldtk
}