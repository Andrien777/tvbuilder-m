extends ColorPickerButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	color = GlobalSettings.wire_color


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_color_changed(color: Color) -> void:
	GlobalSettings.wire_color = color
	GlobalSettings.wire_color_global = color
	GlobalSettings.useDefaultWireColor = false
	for wire in WireManager.wires:
		wire.change_color()


func _on_wire_color_reset_button_pressed() -> void:
	GlobalSettings.useDefaultWireColor = true
	if GlobalSettings.CurrentGraphicsMode == LegacyGraphicsMode:
		color = Color(1, 0, 0)
	else:
		color = Color(1, 1, 1)
	GlobalSettings.wire_color = color
	GlobalSettings.wire_color_global = color
	for wire in WireManager.wires:
		wire.change_color()
