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
	self.set_item_checked(0, GlobalSettings.CurrentGraphicsMode==DefaultGraphicsMode)
	self.set_item_checked(1, GlobalSettings.showLastWire)
	self.set_item_checked(2, GlobalSettings.highlightOutputPins)
	self.set_item_checked(3, not get_node("/root/RootNode/UiCanvasLayer/VBoxContainer/FunctionalUIContainer/ComponentTree").tree_visible)
	self.set_item_checked(4, not get_node("/root/RootNode/UiCanvasLayer/VBoxContainer2/RibbonContainer").visible)
	self.set_item_checked(5, GlobalSettings.turbo)


func _on_index_pressed(index: int) -> void:
	match index:
		0:
			get_node("/root/RootNode").toggle_graphics_mode()
			self.set_item_checked(0, GlobalSettings.CurrentGraphicsMode==DefaultGraphicsMode)
		1:
			GlobalSettings.showLastWire = not GlobalSettings.showLastWire
			self.set_item_checked(1, GlobalSettings.showLastWire)
			get_node("/root/RootNode/UiCanvasLayer/VBoxContainer2/RibbonContainer/ShowLastWireRibbonButton").button_pressed = GlobalSettings.showLastWire
			WireManager.toggle_last_wire_visible()
		2:
			GlobalSettings.highlightOutputPins = not GlobalSettings.highlightOutputPins
			self.set_item_checked(2, GlobalSettings.highlightOutputPins)
			get_node("/root/RootNode/UiCanvasLayer/VBoxContainer2/RibbonContainer/HighlightPinsButton").button_pressed = GlobalSettings.highlightOutputPins
			ComponentManager.toggle_output_highlight()
		3:
			get_node("/root/RootNode/UiCanvasLayer/VBoxContainer/FunctionalUIContainer/ComponentTree").hide_tree()
			self.set_item_checked(3, not get_node("/root/RootNode/UiCanvasLayer/VBoxContainer/FunctionalUIContainer/ComponentTree").tree_visible)
		4:
			if self.is_item_checked(4):
				get_node("/root/RootNode/UiCanvasLayer/VBoxContainer2/RibbonContainer").visible = true
				get_node("/root/RootNode/UiCanvasLayer/VBoxContainer").position.y = 72
				get_node("/root/RootNode/UiCanvasLayer/VBoxContainer").size.y -= 36
				self.set_item_checked(4, false)
			else:
				get_node("/root/RootNode/UiCanvasLayer/VBoxContainer2/RibbonContainer").visible = false
				get_node("/root/RootNode/UiCanvasLayer/VBoxContainer").position.y = 36
				get_node("/root/RootNode/UiCanvasLayer/VBoxContainer").size.y += 36
				self.set_item_checked(4, true)
		5:
			GlobalSettings.turbo = not GlobalSettings.turbo
			if GlobalSettings.turbo:
				Engine.physics_ticks_per_second = 500
				Engine.max_physics_steps_per_frame = 9
			else:
				Engine.physics_ticks_per_second = 60
				Engine.max_physics_steps_per_frame = 8
			self.set_item_checked(5, GlobalSettings.turbo)
		6:
			get_node("../SettingsWindow").open_window()
			self.hide()


func _on_popup_hide() -> void:
	GlobalSettings.save()
	hide()
