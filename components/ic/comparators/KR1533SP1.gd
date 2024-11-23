extends CircuitComponent
class_name KR1533SP1

func _process_signal():
	pin(8).set_low()
	pin(16).set_high()
	var a = ((pin(10).high as int)) | ((pin(12).high as int)<<1) | ((pin(13).high as int)<<2) | ((pin(15).high as int)<<3) 
	var b  = ((pin(9).high as int)) | ((pin(11).high as int)<<1) | ((pin(14).high as int)<<2) | ((pin(1).high as int)<<3)
	if (a > b):
		pin(5).set_high()
		pin(7).set_low()
		pin(6).set_low()
	elif (a < b):
		pin(5).set_low()
		pin(7).set_high()
		pin(6).set_low()
	else:
		if (pin(4).high && pin(3).low && pin(2).low):
			pin(5).set_high()
			pin(7).set_low()
			pin(6).set_low()
		elif (pin(4).low && pin(2).high && pin(3).low):
			pin(5).set_low()
			pin(7).set_high()
			pin(6).set_low()
		elif pin(3).high:
			pin(5).set_low()
			pin(7).set_low()
			pin(6).set_high()
		else:
			pin(6).set_low()
			if pin(4).high:
				pin(5).set_low()
				pin(7).set_low()
			else:
				pin(5).set_high()
				pin(7).set_high()
