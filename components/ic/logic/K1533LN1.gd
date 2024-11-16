extends CircuitComponent


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func _process_signal():
	pin(7).set_low()
	pin(14).set_high()
	pin(2).state = (not pin(1).high) as int
	pin(4).state = (not pin(3).high) as int
	pin(6).state = (not pin(5).high) as int
	pin(8).state = (not pin(9).high) as int
	pin(10).state = (not pin(11).high) as int
	pin(12).state = (not pin(13).high) as int
