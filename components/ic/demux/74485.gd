extends CircuitComponent
class_name D_74485
var res_pins_1: Array[Pin]
var res_pins_2: Array[Pin]
func _ready():
	res_pins_1 = [pin(6),pin(7),pin(8)]
	res_pins_2 = [pin(9),pin(11),pin(12),pin(13)]

func _process_signal():
	if(pin(16).low and pin(15).low):
		var a = ((pin(5).high as int)) | ((pin(4).high as int)<<1) | ((pin(3).high as int)<<2) | ((pin(2).high as int)<<3) | ((pin(1).high as int)<<4)| ((pin(19).high as int)<<5) | ((pin(18).high as int)<<6) | ((pin(17).high as int)<<7)
		var t1 =0 
		var t2 =0 
		var rem = a*2%10
		t1 = int(floor(a*2%10/2.0)) as int
		t2 = int(a*2/10%10) as int
		#t2+=(a*2/10/10)*100
		if((a*2/10/10)!=0): 
			pin(14).set_high()
		else:
			pin(14).set_low()
		
		for _pin in res_pins_1:
			_pin.state = t1&1
			t1 = t1>>1
		for _pin in res_pins_2:
			_pin.state = t2&1
			t2 = t2>>1
