package tools
import "core:encoding/json"
import "core:os"
import "core:log"

parse_string :: proc(data: string) -> json.Value
{
	json_data, err: = json.parse_string(data)
	if err != .None {
		log.errorf("Faile to parse json file ")
		log.errorf("Error:", err)
		return nil
	}

	return json_data
}

load_json :: proc(path: string) -> json.Value
{
	data, ok: = os.read_entire_file_from_filename(path)
	if !ok {
		log.errorf("Faile to load file \"%s\"", path)
		return nil
	}
	defer delete(data) // Free the memory at the end
	
	// Parse the json file.
	json_data, err: = json.parse(data)
	if err != .None {
		log.errorf("Faile to parse json file ")
		log.errorf("Error:", err)
		return nil
	}

	return json_data;
}