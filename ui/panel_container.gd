extends PanelContainer

var running = false
@onready var top_level_parent = (get_node("../../") as Container)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and top_level_parent.visible and not running:
		running = true
		get_node("/root/RootNode/AprilFools").commence_tomfoolery()
		top_level_parent.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
		z_index = 10


func _on_resized() -> void:
	if running:
		top_level_parent.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
