@tool
extends Node3D
@export_group("Save")
@export_tool_button("Save Level")
var save_action = _save
@export var save : Array

@export_group("Load")
@export var fileName = ""

func _input(event: InputEvent) -> void:
	if Input.is_physical_key_pressed(KEY_F15):
		_load()
func _save() -> void:
	save = []
	for i : Node3D in get_tree().get_nodes_in_group("Save"):
		var dict = {"0":-1,"1":Vector3.ZERO,"2":Vector3.ZERO,"3":Vector3.ZERO}
		dict["0"] = _get_id_from_name(i.name)
		dict["1"] = i.global_position.snapped(Vector3.ONE * 0.02)
		dict["2"] = i.global_rotation_degrees.snapped(Vector3.ONE)
		dict["3"] = i.scale.snapped(Vector3.ONE * 0.1)
		if dict["2"] == Vector3.ZERO:
			dict.erase("2")
		if dict["3"] == Vector3.ONE:
			dict.erase("3")
		save.append(dict)
	save_array_to_json(save,"res://SavedLevels/Level - " + Time.get_time_string_from_system().replace(":","") + ".txt")

func _load() -> void:
	var loaded := load_array_from_json(fileName)
	for dict : Dictionary in loaded:
		var obj
		match dict["0"]:
			0.0:
				obj = load("res://Level Pieces/Bricks.tscn").instantiate()
			1.0:
				obj = load("res://Level Pieces/Crate.tscn").instantiate()
			2.0:
				obj = load("res://Level Pieces/Dirt.tscn").instantiate()
			3.0:
				obj = load("res://Level Pieces/Exclamation.tscn").instantiate()
			4.0:
				obj = load("res://Level Pieces/Grass.tscn").instantiate()
			5.0:
				obj = load("res://Level Pieces/Question.tscn").instantiate()
			6.0:
				obj = load("res://Level Pieces/Spikes.tscn").instantiate()
		add_child(obj)
		
		var rawPos : String = dict["1"]
		rawPos = rawPos.replace("(","")
		rawPos = rawPos.replace(")","")
		var pos = rawPos.split(",")
		obj.global_position = Vector3(float(pos[0]),float(pos[1]),float(pos[2]))
		
		if dict.has("2"):
			var rawRot : String = dict["2"]
			rawRot = rawRot.replace("(","")
			rawRot = rawRot.replace(")","")
			var rot = rawRot.split(",")
			obj.global_rotation_degrees = Vector3(float(rot[0]),float(rot[1]),float(rot[2]))
		
		if dict.has("3"):
			var rawScale : String = dict["3"]
			rawScale = rawScale.replace("(","")
			rawScale = rawScale.replace(")","")
			var sca = rawScale.split(",")
			obj.scale = Vector3(float(sca[0]),float(sca[1]),float(sca[2]))

func _get_id_from_name(n : String):
	if n.contains("Bricks"):
		return 0
	if n.contains("Crate"):
		return 1
	if n.contains("Dirt"):
		return 2
	if n.contains("Exclamation"):
		return 3
	if n.contains("Grass"):
		return 4
	if n.contains("Question"):
		return 5
	if n.contains("Spikes"):
		return 6

func save_array_to_json(array_data: Array, file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.WRITE)  # Creates the file if it doesn't exist
	if file:
		var json_string = JSON.stringify(array_data,"\t")  # "\t" adds indentation for readability
		file.store_string(json_string)
		file.close()
		print("Saved successfully to: ", file_path)
	else:
		print("Error: Could not open file for writing at ", file_path)

func load_array_from_json(file_path: String) -> Array:
	if not FileAccess.file_exists(file_path):
		print("File not found: ", file_path)
		return []

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()

	var result = JSON.parse_string(json_string)
	if result != null:
		return result
	else:
		print("JSON parse error: ", result.error_string)
		return []
