extends CircuitComponent

class_name And2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func _process_signal():
	pins[2] = pins[1] & pins[0]
