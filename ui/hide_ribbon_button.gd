extends CheckButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		get_node("/root/RootNode/UiCanvasLayer/VBoxContainer2/RibbonContainer").visible = true
		get_node("/root/RootNode/UiCanvasLayer/VBoxContainer").position.y = 72
		get_node("/root/RootNode/UiCanvasLayer/VBoxContainer").size.y -= 36
	else:
		get_node("/root/RootNode/UiCanvasLayer/VBoxContainer2/RibbonContainer").visible = false
		get_node("/root/RootNode/UiCanvasLayer/VBoxContainer").position.y = 36
		get_node("/root/RootNode/UiCanvasLayer/VBoxContainer").size.y += 36
