extends CircuitComponent
class_name K1533IE5

var counter=0
var div_2=0
var prev_c0=NetConstants.LEVEL.LEVEL_Z
var prev_c1=NetConstants.LEVEL.LEVEL_Z

func _process_signal():
	if(pin(2).high && pin(3).high): # Reset
		counter = 0	
		div_2 = 0
	else:
		if (pin(14).low && prev_c0 == NetConstants.LEVEL.LEVEL_HIGH):
			if div_2 != 0:
				div_2 = 0
			else:
				div_2 = 1
		if (pin(1).low && prev_c1 == NetConstants.LEVEL.LEVEL_HIGH):
			counter += 1
			if counter == 8:
				counter = 0
	
	pin(12).state = div_2
	if (counter & (1 << 0)):
		pin(9).set_high()
	else:
		pin(9).set_low()
	if (counter & (1 << 1)):
		pin(8).set_high()
	else:
		pin(8).set_low()
	if (counter & (1 << 2)):
		pin(11).set_high()
	else:
		pin(11).set_low()
	
	prev_c0 = pin(14).state
	prev_c1 = pin(1).state
		
