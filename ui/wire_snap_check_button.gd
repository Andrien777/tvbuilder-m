extends CheckButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_wire_snap_check_button_toggled(toggled_on: bool) -> void:
	GlobalSettings.WireSnap = toggled_on
