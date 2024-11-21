extends CircuitComponent
class_name K1531TV9

var previous_clock_1
var previous_clock_2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pin(5).set_low()
	pin(6).set_high()
	pin(9).set_low()
	pin(7).set_high()


func _process_signal():
	pin(8).set_low()
	pin(16).set_high()
	if(pin(15).low && pin(4).high):
		pin(5).set_low()
		pin(6).set_high()
	elif (pin(4).low && pin(15).high):
		pin(5).set_high()
		pin(6).set_low()
	elif (pin(4).low && pin(15).low):
		pin(5).set_high()
		pin(6).set_high()
	else:
		if(previous_clock_1==NetConstants.LEVEL.LEVEL_HIGH and pin(1).low):
			if (pin(2).high):
				if (pin(3).high):
					if (pin(5).low):
						pin(5).set_high()
						pin(6).set_low()
					else:
						pin(5).set_low()
						pin(6).set_high()
				else:
					pin(5).set_low()
					pin(6).set_high()
			elif (pin(3).high):
				pin(5).set_high()
				pin(6).set_low()
	previous_clock_1 = pin(1).state
	if(pin(14).low && pin(10).high):
		pin(9).set_low()
		pin(7).set_high()
	elif (pin(10).low && pin(14).high):
		pin(9).set_high()
		pin(7).set_low()
	elif (pin(10).low && pin(14).low):
		pin(9).set_high()
		pin(7).set_high()
	else:
		if(previous_clock_2==NetConstants.LEVEL.LEVEL_HIGH and pin(13).low):
			if (pin(12).high):
				if (pin(11).high):
					if (pin(9).low):
						pin(9).set_high()
						pin(7).set_low()
					else:
						pin(9).set_low()
						pin(7).set_high()
				else:
					pin(9).set_low()
					pin(7).set_high()
			elif (pin(5).high):
				pin(9).set_high()
				pin(7).set_low()
	previous_clock_2 = pin(13).state
		
