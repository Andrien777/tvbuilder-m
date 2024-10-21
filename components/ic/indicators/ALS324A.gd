extends CircuitComponent
class_name ALS324A
static var lut = {
	[1,1,1,1,1,1,0]:0,
	[0,1,1,0,0,0,0]:1,
	[1,1,0,1,1,0,1]:2,
	[1,1,1,1,0,0,1]:3,
	[0,1,1,0,0,1,1]:4,
	[0,1,1,1,0,1,1]:5,
	[0,0,1,1,1,1,1]:6,
	[1,1,1,0,0,0,0]:7,
	[1,1,1,1,1,1,1]:8,
	[1,1,1,0,0,1,1]:9,
	[0,0,0,1,1,0,1]:10,
	[0,0,1,1,0,0,1]:11,
	[0,1,0,0,0,1,1]:12,
	[1,0,0,1,0,1,1]:13,
	[0,0,0,1,1,1,1]:14,
	[0,0,0,0,0,0,0]:15
	}
var label
func _init():
	label = Label.new()
	label.position = self.position + Vector2(-20,-20)
	label.z_index = 2
	label.text = "test"
	add_child(label)
	
func _process_signal():
	var inputs = [pin(14).high as int,pin(13).high as int,pin(8).high as int,pin(7).high as int,pin(6).high as int ,pin(1).high as int ,pin(2).high as int]

	if inputs in lut.keys():
		label.text = str(lut[inputs])
	else:
		label.text = "?"
