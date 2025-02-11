extends CircuitComponent
class_name K1533ID4


func _process_signal():
	pin(8).set_low()
	pin(16).set_high()
	if pin(1).low: # Bottom half enabled
		if (pin(3).high_or_z and pin(13).high_or_z):
			pin(7).set_high()
			pin(6).set_high()
			pin(5).set_high()
			pin(4).set_low()
		if (pin(3).high_or_z and pin(13).low):
			pin(7).set_high()
			pin(6).set_high()
			pin(5).set_low()
			pin(4).set_high()
		if (pin(3).low and pin(13).high_or_z):
			pin(7).set_high()
			pin(6).set_low()
			pin(5).set_high()
			pin(4).set_high()
		if (pin(3).low and pin(13).low):
			pin(7).set_low()
			pin(6).set_high()
			pin(5).set_high()
			pin(4).set_high()
	else:
		pin(7).set_high()
		pin(6).set_high()
		pin(5).set_high()
		pin(4).set_high()

	if pin(15).low: # Upper half enabled
		if (pin(3).high_or_z and pin(13).high_or_z):
			pin(9).set_high()
			pin(10).set_high()
			pin(11).set_high()
			pin(12).set_low()
		if (pin(3).high_or_z and pin(13).low):
			pin(9).set_high()
			pin(10).set_high()
			pin(11).set_low()
			pin(12).set_high()
		if (pin(3).low and pin(13).high_or_z):
			pin(9).set_high()
			pin(10).set_low()
			pin(11).set_high()
			pin(12).set_high()
		if (pin(3).low and pin(13).low):
			pin(9).set_low()
			pin(10).set_high()
			pin(11).set_high()
			pin(12).set_high()
	else:
		pin(9).set_high()
		pin(10).set_high()
		pin(11).set_high()
		pin(12).set_high()
