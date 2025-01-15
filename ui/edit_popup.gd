extends PopupMenu


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_edit_button_pressed() -> void:
	self.visible = true
	self.position = get_node("../EditButton").position + Vector2(get_node("/root/RootNode").get_window().position) + Vector2(-2, 36)


func _on_index_pressed(index: int) -> void:
	match index:
		0:
			HistoryBuffer.undo_last_event()
		1:
			HistoryBuffer.redo_last_event()
		2:
			CopyBuffer.copy(get_node("/root/RootNode/Camera2D").get_screen_center_position())
			get_node("/root/RootNode/SelectionArea").remember_copy_offset(get_node("/root/RootNode/Camera2D").get_screen_center_position())
		3:
			CopyBuffer.paste(get_node("/root/RootNode/Camera2D").get_screen_center_position())
			get_node("/root/RootNode/SelectionArea").paste_copy_offset(get_node("/root/RootNode/Camera2D").get_screen_center_position())
