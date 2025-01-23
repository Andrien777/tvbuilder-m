extends ColorPickerButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	color = GlobalSettings.bus_color


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_color_changed(color: Color) -> void:
	GlobalSettings.bus_color = color
	GlobalSettings.bus_color_global = color
	GlobalSettings.useDefaultWireColor = false
	for bus in WireManager.buses:
		bus.change_color()


func _on_wire_color_reset_button_pressed() -> void:
	GlobalSettings.useDefaultWireColor = true
	if GlobalSettings.CurrentGraphicsMode == LegacyGraphicsMode:
		color = Color(1, 0, 0)
	else:
		color = Color(1, 1, 1)
	GlobalSettings.bus_color = color
	GlobalSettings.bus_color_global = color
	for bus in WireManager.buses:
		bus.change_color()
