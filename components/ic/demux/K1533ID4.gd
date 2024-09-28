extends CircuitComponent
class_name K1533ID4


func _process_signal():
	if pins[0].low():
		if (pins[2].high_or_z() and pins[12].high_or_z()):
			pins[6].set_high()
			pins[5].set_high()
			pins[4].set_high()
			pins[3].set_low()
		if (pins[2].state==NetConstants.LEVEL.LEVEL_HIGH and pins[12].state==NetConstants.LEVEL.LEVEL_LOW):
			pins[6].state = NetConstants.LEVEL.LEVEL_HIGH
			pins[5].state = NetConstants.LEVEL.LEVEL_HIGH
			pins[4].state = NetConstants.LEVEL.LEVEL_LOW
			pins[3].state = NetConstants.LEVEL.LEVEL_HIGH
		if (pins[2].state==NetConstants.LEVEL.LEVEL_LOW and pins[12].state==NetConstants.LEVEL.LEVEL_HIGH):
			pins[6].state = NetConstants.LEVEL.LEVEL_HIGH
			pins[5].state = NetConstants.LEVEL.LEVEL_LOW
			pins[4].state = NetConstants.LEVEL.LEVEL_HIGH
			pins[3].state = NetConstants.LEVEL.LEVEL_HIGH
		if (pins[2].state==NetConstants.LEVEL.LEVEL_LOW and pins[12].state==NetConstants.LEVEL.LEVEL_LOW):
			pins[6].state = NetConstants.LEVEL.LEVEL_LOW
			pins[5].state = NetConstants.LEVEL.LEVEL_HIGH
			pins[4].state = NetConstants.LEVEL.LEVEL_HIGH
			pins[3].state = NetConstants.LEVEL.LEVEL_HIGH
	else:
		pins[6].set_z()
		pins[5].set_z()
		pins[4].set_z()
		pins[3].set_z()
