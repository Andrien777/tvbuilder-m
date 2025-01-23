extends CircuitComponent
class_name K1531IR22

var state: Array
var inputs: Array
var outputs: Array
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	inputs = [3, 4, 7, 8, 13, 14, 17, 18]
	outputs = [2, 5, 6, 9, 12, 15, 16, 19]
	state = [0, 0, 0, 0, 0, 0, 0, 0]
	

func save_state():
	for i in range(inputs.size()):
		state[i] = pin(inputs[i]).high_or_z as int


func load_state():
	for i in range(outputs.size()):
		pin(outputs[i]).state = state[i]


	
func _process_signal():
	pin(10).set_low()
	pin(20).set_high()
	if (pin(1).low):
		if pin(11).high:
			save_state()
		load_state()
	else:
		for i in range(outputs.size()):
			pin(outputs[i]).set_z()
