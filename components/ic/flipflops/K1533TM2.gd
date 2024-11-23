extends CircuitComponent
class_name K1533TM2

var previous_clock_1
var previous_clock_2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pin(5).set_low()
	pin(6).set_high()
	pin(9).set_low()
	pin(8).set_high()


func _process_signal():
	pin(7).set_low()
	pin(14).set_high()
	if(pin(1).low && pin(2).high): # D1 RST
		pin(5).set_low()
		pin(6).set_high()
	elif (pin(2).low && pin(1).high): 
		pin(5).set_high() # D1 SET
		pin(6).set_low()
	elif (pin(1).low && pin(2).low):
		pin(5).set_high()
		pin(6).set_high()
	else:
		if(previous_clock_1==NetConstants.LEVEL.LEVEL_LOW and pin(3).high): # Rising edge on C1
			if(pin(2).low): # If input D1 is low
				pin(5).set_low()
				pin(6).set_high()
			else: # Z as high
				pin(5).set_high() # D1 SET
				pin(6).set_low()
	previous_clock_1 = pin(3).state
	if (pin(13).low && pin(10).high): # D2 RST
		pin(9).set_low()
		pin(8).set_high()
	elif (pin(10).low && pin(13).high):
		pin(9).set_high() # D2 SET
		pin(8).set_low()
	elif (pin(10).low && pin(13).low):
		pin(9).set_high()
		pin(8).set_high()
	else:
		if(previous_clock_2==NetConstants.LEVEL.LEVEL_LOW and pin(11).high): # Rising edge on C2
			if(pin(12).low): # If input D2 is low
				pin(9).set_low()
				pin(8).set_high()
			else: # Z as high
				pin(9).set_high() # D2 SET
				pin(8).set_low()
	previous_clock_2 = pin(11).state
		
