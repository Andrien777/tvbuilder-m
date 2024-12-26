extends PopupMenu


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_settings_button_pressed() -> void:
	self.visible = true
	self.position = get_node("../SettingsButton").position + Vector2(get_node("/root/RootNode").get_window().position) + Vector2(-3, 36)
	self.set_item_checked(0, not GlobalSettings.doCycles)
	self.set_item_checked(1, GlobalSettings.CurrentGraphicsMode==DefaultGraphicsMode)


func _on_index_pressed(index: int) -> void:
	match index:
		0:
			GlobalSettings.doCycles = not GlobalSettings.doCycles
			self.set_item_checked(0, not GlobalSettings.doCycles)
		1:
			get_node("/root/RootNode").toggle_graphics_mode()
			self.set_item_checked(1, GlobalSettings.CurrentGraphicsMode==DefaultGraphicsMode)
		2:
			get_node("../SettingsWindow").open_window()
			self.hide()
