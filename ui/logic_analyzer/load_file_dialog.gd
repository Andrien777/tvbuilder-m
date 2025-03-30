extends FileDialog


func _ready() -> void:
	#current_dir = "user://" 
	add_filter("*.json")


func _on_load_button_pressed() -> void:
	visible = true


func _on_file_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if FileAccess.get_open_error() != OK:
		file.close()
		push_error("Failed to open file for reading: %s" % path)
		return 

	var json_string = file.get_as_text()
	file.close()

	var parse_result = JSON.parse_string(json_string)
	var group_signals_indexes: Array[Array]
	
	%SignalsHSplitContainer.signals = []
	for item_dict in parse_result:
		if typeof(item_dict) != TYPE_DICTIONARY:
			push_warning("Invalid item found in JSON data (expected Dictionary).")
			continue

		var class_name_ = item_dict.get("class_name")
		if class_name_ == "LASignal":
			_add_signal_from_dict(item_dict)
		elif class_name_ == "LASignalGroup":
			group_signals_indexes.append([])
			
			for sig in item_dict.get("signals"):
				group_signals_indexes.back().append(
					%SignalsHSplitContainer.signals.size()
				)
				_add_signal_from_dict(sig)
	
	var group_i = 0
	for item_dict in parse_result:
		if item_dict.get("class_name") == "LASignalGroup":
			var signals = []
			for sig_ind in group_signals_indexes[group_i]:
				signals.append(%SignalsHSplitContainer.signals[sig_ind])
			item_dict.get("name")
			item_dict.get("radix")
			%SignalsHSplitContainer.add_group(
				signals,
				item_dict.get("name"),
				item_dict.get("radix")
			)
			group_i += 1


func _add_signal_from_dict(dict):
	var packed_color_array = \
		(dict.get("color") as String)\
			.trim_prefix("(").trim_suffix(")")\
			.split(",")
	var color_array = []
	for item in packed_color_array:
		color_array.append(item.to_float())
		
	var color = Color(color_array[0], color_array[1], color_array[2], color_array[3])
	%SignalsHSplitContainer.add_signal_(
		dict.get("ic_id") ,
		dict.get("pin_index"),
		dict.get("name"),
		color,
		dict.get("signal_points"),
	)
