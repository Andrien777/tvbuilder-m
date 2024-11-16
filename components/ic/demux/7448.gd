extends CircuitComponent
class_name D_7448
var outs: Array[Pin]
static var lut = {
	0:[1,1,1,1,1,1,0],
	1:[0,1,1,0,0,0,0],
	2:[1,1,0,1,1,0,1],
	3:[1,1,1,1,0,0,1],
	4:[0,1,1,0,0,1,1],
	5:[0,1,1,1,0,1,1],
	6:[0,0,1,1,1,1,1],
	7:[1,1,1,0,0,0,0],
	8:[1,1,1,1,1,1,1],
	9:[1,1,1,0,0,1,1],
	10:[0,0,0,1,1,0,1],
	11:[0,0,1,1,0,0,1],
	12:[0,1,0,0,0,1,1],
	13:[1,0,0,1,0,1,1],
	14:[0,0,0,1,1,1,1],
	15:[0,0,0,0,0,0,0]
	}
func _ready():
	outs  = [pin(13),pin(12),pin(11),pin(10),pin(9),pin(15),pin(14)]
func _process_signal():
	pin(8).set_low()
	pin(16).set_high()
	pin(4).set_high()
	var a = ((pin(7).high as int)) | ((pin(1).high as int)<<1) | ((pin(2).high as int)<<2) | ((pin(6).high as int)<<3) 
	if(pin(3).high): # LT
		for i in range(0,7):
			outs[i].state = lut[8][i]
	if(pin(5).low): # RBI
		if a == 0:
			a = 15
			pin(4).set_low()
	for i in range(0,7):
		outs[i].state = lut[a][i]
