extends ColorPickerButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	color = GlobalSettings.bus_color


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_color_changed(color: Color) -> void:
	GlobalSettings.label_color = color
	GlobalSettings.label_color_global = color
	for component in ComponentManager.obj_list.values():
		component.change_color()
	for bus in WireManager.buses:
		bus.change_color()


func _on_wire_color_reset_button_pressed() -> void:
	color = Color(1, 1, 1)
	GlobalSettings.label_color = color
	GlobalSettings.label_color_global = color
	for component in ComponentManager.obj_list.values():
		component.change_color()
	for bus in WireManager.buses:
		bus.change_color()
