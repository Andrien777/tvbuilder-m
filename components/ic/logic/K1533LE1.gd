extends CircuitComponent


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func _process_signal():
	pin(7).set_low()
	pin(14).set_high()
	pin(3).state = (not (pin(2).high || pin(1).high)) as int
	pin(6).state = (not (pin(4).high || pin(5).high)) as int
	pin(8).state = (not (pin(9).high || pin(10).high)) as int
	pin(11).state = (not (pin(12).high || pin(13).high)) as int
