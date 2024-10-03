extends CircuitComponent

class_name Tristate

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func _process_signal():
	if pins[1].high:
		pins[2].state = pins[0].state
	else:
		pins[2].set_z()
