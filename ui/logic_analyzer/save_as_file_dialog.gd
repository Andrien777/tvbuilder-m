extends FileDialog


func _ready() -> void:
	current_dir = "user://" 
	add_filter("*.tvbwave")


func _on_save_button_pressed() -> void:
	visible = true


func _on_file_selected(path: String) -> void:
	if path.get_extension() != "tvbwave":
		path = path + ".tvbwave"
	var serializable_list: Array[Dictionary] = [] 
	
	for sig in %SignalsHSplitContainer.signals:
		serializable_list.append(sig.to_dict())
	
	var json = JSON.stringify(serializable_list, '\t')
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if FileAccess.get_open_error() != OK:
		push_error("Failed to open file for writing: %s" % path)

	file.store_string(json)
	file.close()
