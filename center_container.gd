extends VBoxContainer

var running = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and visible and not running:
		running = true
		get_node("/root/RootNode/AprilFools").commence_tomfoolery()
		set_anchors_preset(Control.PRESET_CENTER_RIGHT, true)
		z_index = 10
