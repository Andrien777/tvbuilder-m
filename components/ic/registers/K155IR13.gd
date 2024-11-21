extends CircuitComponent

var outputs
var s0
var s1
var previous_clock
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	outputs = [pin(4),pin(6),pin(8),pin(10), pin(14),pin(16), pin(18), pin(20)]
	s0 = pin(1)
	s1 = pin(23)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process_signal() -> void:
	pin(12).set_low()
	pin(24).set_high()
	if(pin(13).low):
		for out in outputs: # reset all outputs to low
			out.set_low()
	else:
		if(pin(11).high and previous_clock == NetConstants.LEVEL.LEVEL_LOW):
			if(s0.low and s1.low):
				pass # Do nothing. Store.
			elif (s0.high and s1.low): # Left shift
				for i in range(len(outputs)-1,0,-1):
					outputs[i].state = outputs[i-1].state
				outputs[0].state = pin(22).state # TODO: Make it .high_or_z
			elif (s0.low and s1.high): # Right shift
				for i in range(1, len(outputs)):
					outputs[i-1].state = outputs[i].state
				outputs[-1].state = pin(2).state #TODO: .high_or_z
			elif (s0.high and s1.high): # Load
				outputs[0].state = pin(3).state
				outputs[1].state = pin(5).state
				outputs[2].state = pin(7).state
				outputs[3].state = pin(9).state
				outputs[4].state = pin(15).state
				outputs[5].state = pin(17).state
				outputs[6].state = pin(19).state
				outputs[7].state = pin(21).state
	previous_clock = pin(11).state
