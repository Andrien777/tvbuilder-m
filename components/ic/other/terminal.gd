extends CircuitComponent

class_name Terminal

var label: Label
var text:
	get():
		return label.text
	set(new_text):
		label.text = new_text
var msg: int = 0
var counter = 0
var receiving = false
var prev_clk = false

func initialize(spec, ic=null):
	display_name_label = false
	super.initialize(spec, ic)
	label = Label.new()
	add_child(label)
	
func _process_signal():
	var clk = pin(2).high
	if clk and not prev_clk:
		if not receiving:
			if pin(1).low:
				receiving = true
				counter = 0
		else:
			if counter < 8:
				if pin(1).high:
					msg += int(pow(2, counter))
				counter += 1
			if counter == 8:
				if msg == 7:
					text = ""
				else:
					text = text + String.chr(msg)
				receiving = false
				msg = 0
	prev_clk = clk
