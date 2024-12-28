extends CheckButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	GlobalSettings.showLastWire = not GlobalSettings.showLastWire
	self.button_pressed = GlobalSettings.showLastWire
	WireManager.toggle_last_wire_visible()
