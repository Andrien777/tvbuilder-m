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
	self.set_item_checked(2, GlobalSettings.showLastWire)
	self.set_item_checked(3, GlobalSettings.highlightOutputPins)
	self.set_item_checked(4, not get_node("/root/RootNode/UiCanvasLayer/VBoxContainer/FunctionalUIContainer/ComponentTree").tree_visible)
	self.set_item_checked(5, not get_node("/root/RootNode/UiCanvasLayer/VBoxContainer2/RibbonContainer").visible)


func _on_index_pressed(index: int) -> void:
	match index:
		0:
			GlobalSettings.doCycles = not GlobalSettings.doCycles
			self.set_item_checked(0, not GlobalSettings.doCycles)
		1:
			get_node("/root/RootNode").toggle_graphics_mode()
			self.set_item_checked(1, GlobalSettings.CurrentGraphicsMode==DefaultGraphicsMode)
		2:
			GlobalSettings.showLastWire = not GlobalSettings.showLastWire
			self.set_item_checked(2, GlobalSettings.showLastWire)
			get_node("/root/RootNode/UiCanvasLayer/VBoxContainer2/RibbonContainer/ShowLastWireRibbonButton").button_pressed = GlobalSettings.showLastWire
			WireManager.toggle_last_wire_visible()
		3:
			GlobalSettings.highlightOutputPins = not GlobalSettings.highlightOutputPins
			self.set_item_checked(3, GlobalSettings.highlightOutputPins)
			get_node("/root/RootNode/UiCanvasLayer/VBoxContainer2/RibbonContainer/HighlightPinsButton").button_pressed = GlobalSettings.highlightOutputPins
			ComponentManager.toggle_output_highlight()
		4:
			get_node("/root/RootNode/UiCanvasLayer/VBoxContainer/FunctionalUIContainer/ComponentTree").hide_tree()
			self.set_item_checked(4, not get_node("/root/RootNode/UiCanvasLayer/VBoxContainer/FunctionalUIContainer/ComponentTree").tree_visible)
		5:
			if self.is_item_checked(5):
				get_node("/root/RootNode/UiCanvasLayer/VBoxContainer2/RibbonContainer").visible = true
				get_node("/root/RootNode/UiCanvasLayer/VBoxContainer").position.y = 72
				get_node("/root/RootNode/UiCanvasLayer/VBoxContainer").size.y -= 36
				self.set_item_checked(5, false)
			else:
				get_node("/root/RootNode/UiCanvasLayer/VBoxContainer2/RibbonContainer").visible = false
				get_node("/root/RootNode/UiCanvasLayer/VBoxContainer").position.y = 36
				get_node("/root/RootNode/UiCanvasLayer/VBoxContainer").size.y += 36
				self.set_item_checked(5, true)
		6:
			get_node("../SettingsWindow").open_window()
			self.hide()


func _on_popup_hide() -> void:
	GlobalSettings.save()
	hide()
