extends CircuitComponent
class_name K1533ID4
var sprite: Sprite2D

func _process_signal():
	if pins[0].state == NetConstants.LEVEL.LEVEL_LOW:
		if (pins[2].state==NetConstants.LEVEL.LEVEL_HIGH and pins[11].state==NetConstants.LEVEL.LEVEL_HIGH):
			pins[6].state = NetConstants.LEVEL.LEVEL_HIGH
			pins[5].state = NetConstants.LEVEL.LEVEL_HIGH
			pins[4].state = NetConstants.LEVEL.LEVEL_HIGH
			pins[3].state = NetConstants.LEVEL.LEVEL_LOW
		if (pins[2].state==NetConstants.LEVEL.LEVEL_HIGH and pins[11].state==NetConstants.LEVEL.LEVEL_LOW):
			pins[6].state = NetConstants.LEVEL.LEVEL_HIGH
			pins[5].state = NetConstants.LEVEL.LEVEL_HIGH
			pins[4].state = NetConstants.LEVEL.LEVEL_LOW
			pins[3].state = NetConstants.LEVEL.LEVEL_HIGH
		if (pins[2].state==NetConstants.LEVEL.LEVEL_LOW and pins[11].state==NetConstants.LEVEL.LEVEL_HIGH):
			pins[6].state = NetConstants.LEVEL.LEVEL_HIGH
			pins[5].state = NetConstants.LEVEL.LEVEL_LOW
			pins[4].state = NetConstants.LEVEL.LEVEL_HIGH
			pins[3].state = NetConstants.LEVEL.LEVEL_HIGH
		if (pins[2].state==NetConstants.LEVEL.LEVEL_LOW and pins[11].state==NetConstants.LEVEL.LEVEL_LOW):
			pins[6].state = NetConstants.LEVEL.LEVEL_LOW
			pins[5].state = NetConstants.LEVEL.LEVEL_HIGH
			pins[4].state = NetConstants.LEVEL.LEVEL_HIGH
			pins[3].state = NetConstants.LEVEL.LEVEL_HIGH
	else:
		pins[6].state = NetConstants.LEVEL.LEVEL_Z
		pins[5].state = NetConstants.LEVEL.LEVEL_Z
		pins[4].state = NetConstants.LEVEL.LEVEL_Z
		pins[3].state = NetConstants.LEVEL.LEVEL_Z
