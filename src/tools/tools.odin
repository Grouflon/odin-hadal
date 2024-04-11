package tools
import "core:encoding/json"
import "core:os"
import "core:log"


load_json :: proc(path:string) -> json.Value
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