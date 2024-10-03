extends CircuitComponent

class_name Memory

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var memory: NetConstants.LEVEL

func _process_signal():
	if pins[1].high:
		pins[0].current_direction = NetConstants.DIRECTION.DIRECTION_INPUT
		memory = pins[0].state
	else:
		pins[0].current_direction = NetConstants.DIRECTION.DIRECTION_OUTPUT
		pins[0].state = memory
