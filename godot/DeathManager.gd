extends Area3D
func _die(group):
	if group.is_in_group("Hazard"):
		get_tree().reload_current_scene()
