extends CircuitComponent
class_name K1533KP11A

# ВХОД: 1A,2A,3A,4A | 1B,2B,3B,4B
const INPUT_PINS_A: Array[int] = [2, 5, 11, 14]
const INPUT_PINS_B: Array[int] = [3, 6, 10, 13]

# ВЫХОД: 1Q,2Q,3Q,4Q
const OUT_PINS_Q: Array[int] = [4, 7, 9, 12]

func _ready():
	pass

func _process_signal():
	pin(8).set_low()   	# GND
	pin(16).set_high()  # VCC

	if pin(15).high:	# ~CS
		_set_all_outputs_low()
	else:
		if pin(1).low:
			_set_output_from(INPUT_PINS_A)
		else:
			_set_output_from(INPUT_PINS_B)

# --------------------

func _set_all_outputs_low() -> void:
	for n in OUT_PINS_Q:
		pin(n).set_low()

func _set_output_from(nums: Array[int]) -> void:
	for i in range(4):
		if 	pin(nums[i]).low: 	pin(OUT_PINS_Q[i]).set_low()
		else:					pin(OUT_PINS_Q[i]).set_high()
