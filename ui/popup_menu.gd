extends PopupMenu


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_file_button_pressed() -> void:
	self.visible = true
	self.position = get_node("../FileButton").position + Vector2(get_node("/root/RootNode").get_window().position) + Vector2(0, 36)


func _on_index_pressed(index: int) -> void:
	match index:
		0:
			_on_save_button_pressed()
		1:
			get_node("/root/RootNode/SaveAsFileDialog")._on_save_as_button_pressed()
		2:
			get_node("/root/RootNode/LoadFileDialog")._on_load_button_pressed()
		3:
			_on_clear_button_pressed()

func _on_clear_button_pressed():
	ComponentManager.clear()
	SaveManager.last_path = ""
	GlobalSettings.bg_color = GlobalSettings.bg_color_global
	GlobalSettings.wire_color = GlobalSettings.wire_color_global
	for wire in WireManager.wires:
		wire.change_color()
	get_node("/root/RootNode/GridSprite").modulate = GlobalSettings.bg_color
	get_window().title = "TVBuilder - New Project"

func _on_save_button_pressed():
	if SaveManager.last_path == "":
		get_node("/root/RootNode/SaveAsFileDialog")._on_save_as_button_pressed()
	else:
		SaveManager._on_autosave()
