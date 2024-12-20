extends PopupMenu


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_file_button_pressed() -> void:
	self.visible = true
	self.position = get_node("../FileButton").position + Vector2(get_node("/root/RootNode").get_window().position) + Vector2(5, 41)


func _on_index_pressed(index: int) -> void:
	match index:
		0:
			if SaveManager.last_path == "":
				get_node("/root/RootNode/SaveAsFileDialog")._on_save_as_button_pressed()
			else:
				SaveManager._on_autosave()
		1:
			get_node("/root/RootNode/SaveAsFileDialog")._on_save_as_button_pressed()
		2:
			get_node("/root/RootNode/LoadFileDialog")._on_load_button_pressed()
		3:
			ComponentManager.clear()
