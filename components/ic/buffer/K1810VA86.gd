extends CircuitComponent

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


var inputs
var outputs
func _process_signal():
	pin(10).set_low()
	pin(20).set_high()
	outputs = Array()
	inputs = Array()
	if (pin(11).high):
		for i in range(12, 20):
			(pin(i) as IO_Pin).set_output()
			outputs.append(pin(i) as IO_Pin)
		for i in range(1, 9):
			(pin(i) as IO_Pin).set_input()
			inputs.append(pin(i) as IO_Pin)
	else:
		for i in range(12, 20):
			(pin(i) as IO_Pin).set_input()
			inputs.append(pin(i) as IO_Pin)
		for i in range(1, 9):
			(pin(i) as IO_Pin).set_output()
			outputs.append(pin(i) as IO_Pin)
	outputs.reverse()
	for i in range(8):
		if (pin(9).high):
			outputs[i].set_z()
		else:
			outputs[i].state = inputs[i].state
