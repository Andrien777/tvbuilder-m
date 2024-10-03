extends CircuitComponent
class_name D_74485
var res_pins_1: Array[Pin]
var res_pins_2: Array[Pin]
func _ready():
	res_pins_1 = [pin(6),pin(7),pin(8),pin(9)]
	res_pins_2 = [pin(11),pin(12),pin(13),pin(14)]

func _process_signal():
	if(pin(16).high and pin(15).high):
		var a = ((pin(5).high as int)) | ((pin(4).high as int)<<1) | ((pin(3).high as int)<<2) | ((pin(2).high as int)<<3) | ((pin(1).high as int)<<4)| ((pin(19).high as int)<<5) | ((pin(18).high as int)<<6) | ((pin(17).high as int)<<7)
		var t1 = a%10
		var t2 = a/10%10
		for _pin in res_pins_1:
			_pin.state = t1&1
			t1 = t1>>1
		for _pin in res_pins_2:
			_pin.state = t2&1
			t2 = t2>>1
