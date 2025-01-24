extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.visible = GlobalSettings.is_bus_mode()


func _on_pressed() -> void:
	WireManager.finish_current_bus()
	get_node("/root/RootNode").to_normal_mode()


func _on_mouse_entered() -> void:
	GlobalSettings.disableGlobalInput = true

func _on_mouse_exited() -> void:
	GlobalSettings.disableGlobalInput = false
