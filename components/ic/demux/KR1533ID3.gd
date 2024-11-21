extends CircuitComponent
class_name KR1533ID3

var outputs = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15, 16, 17]

func _process_signal():
	pins[11].set_low()
	pins[23].set_high()
	if pin(19).high || pin(18).high:
		for out in outputs:
			pin(out).set_high()
	else:
		var a = ((pin(23).high as int)) | ((pin(22).high as int)<<1) | ((pin(21).high as int)<<2) | ((pin(20).high as int)<<3) 
		for out in outputs:
			pin(out).set_high()
		if (a != 0):
			pin(outputs[a - 1]).set_low()
