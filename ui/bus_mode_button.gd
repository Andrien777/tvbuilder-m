extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	button_pressed = GlobalSettings.is_bus_mode()


func _on_pressed() -> void:
	get_node("/root/RootNode").to_bus_mode()
