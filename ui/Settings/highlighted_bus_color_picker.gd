extends ColorPickerButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	color = GlobalSettings.highlightedBusColor


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_color_changed(color: Color) -> void:
	GlobalSettings.highlightedBusColor = color


func _on_wire_color_reset_button_pressed() -> void:
	color = Color(0.7,0.7,0.7,1)
	GlobalSettings.highlightedBusColor = color
