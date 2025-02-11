extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	GlobalSettings.highlightOutputPins = not GlobalSettings.highlightOutputPins
	get_node("/root/RootNode/UiCanvasLayer/VBoxContainer2/RibbonContainer/HighlightPinsButton").button_pressed = GlobalSettings.highlightOutputPins
	ComponentManager.toggle_output_highlight()
