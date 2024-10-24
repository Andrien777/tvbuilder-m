extends CircuitComponent
class_name K1533IE7

var counter=0
var prev_up
var prev_down
func _process_signal():
	if(pin(14).high): # Reset
		counter = 0
	elif (pin(11).low): # Load signal is low(active)
		counter = pin(15).high as int + (pin(1).high as int << 1) + (pin(10).high as int <<2) + (pin(9).high as int <<3)
	elif (pin(5).high and pin(4).high and prev_up == NetConstants.LEVEL.LEVEL_LOW): # Rise edge on +1
		counter+=1
	elif (pin(5).high and pin(4).high and prev_down == NetConstants.LEVEL.LEVEL_LOW): # Rise edge on -1
		counter-=1
	

	
	if(counter==15):
		pin(12).set_low()
	else:
		pin(12).set_high()
	
	if(counter==0):
		pin(13).set_low()
	else:
		pin(13).set_high()

	# Output the value
	if(counter & (1)):
		pin(3).set_high()
	else:
		pin(3).set_low()
	if(counter & (1<<1)):
		pin(2).set_high()
	else:
		pin(2).set_low()
	if(counter & (1<<2)):
		pin(6).set_high()
	else:
		pin(6).set_low()
	if(counter & (1<<3)):
		pin(7).set_high()
	else:
		pin(7).set_low()
	prev_up = pin(5).state
	prev_down = pin(4).state
