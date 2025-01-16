extends ColorPickerButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	color = GlobalSettings.highlightedPinsColor


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_color_changed(color: Color) -> void:
	GlobalSettings.highlightedPinsColor = color


func _on_wire_color_reset_button_pressed() -> void:
	color = Color(0.3,0.3,0.3,1)
	GlobalSettings.highlightedPinsColor = color
