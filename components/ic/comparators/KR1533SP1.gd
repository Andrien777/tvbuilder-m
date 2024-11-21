extends CircuitComponent
class_name KR1533SP1

func _process_signal():
	pin(8).set_low()
	pin(16).set_high()
	var a = ((pin(10).high as int)) | ((pin(7).high as int)<<1) | ((pin(2).high as int)<<2) | ((pin(15).high as int)<<3) 
	var b  = ((pin(11).high as int)) | ((pin(9).high as int)<<1) | ((pin(1).high as int)<<2) | ((pin(14).high as int)<<3)
	if (a > b):
		pin(13).set_high()
		pin(12).set_low()
		pin(3).set_low()
	elif (a < b):
		pin(13).set_low()
		pin(12).set_high()
		pin(3).set_low()
	else:
		if (pin(4).high && pin(5).low && pin(6).low):
			pin(13).set_high()
			pin(12).set_low()
			pin(3).set_low()
		elif (pin(4).low && pin(5).high && pin(6).low):
			pin(13).set_low()
			pin(12).set_high()
			pin(3).set_low()
		elif pin(6).high:
			pin(13).set_low()
			pin(12).set_low()
			pin(3).set_high()
		else:
			pin(3).set_low()
			if pin(4).high:
				pin(13).set_low()
				pin(12).set_low()
			else:
				pin(13).set_high()
				pin(12).set_high()
