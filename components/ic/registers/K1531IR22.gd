extends CircuitComponent
class_name K1531IR22


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	

	
func _process_signal():
	if (pin(1).low):
		if pin(13).high:
			pin(2).state = pin(3).state
			pin(5).state = pin(4).state
			pin(6).state = pin(7).state
			pin(9).state = pin(8).state
			pin(12).state = pin(11).state
			pin(15).state = pin(14).state
			pin(16).state = pin(17).state
			pin(19).state = pin(18).state
	else:
		pin(2).set_z()
		pin(5).set_z()
		pin(6).set_z()
		pin(9).set_z()
		pin(12).set_z()
		pin(15).set_z()
		pin(16).set_z()
		pin(19).set_z()
