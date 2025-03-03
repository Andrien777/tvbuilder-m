extends Node

class_name LA_signal
	
var line_edit: LineEdit
var signal_line: LA_signal_line 

var signal_points: Array[Array] = []  # Array of pairs time(ms) to level [float, NetConstants.LEVEL]
	
var ic_id: int
var pin_index: int

func _init(
	line_edit: LineEdit,
	zoom_factor: float,
	line_color: Color,
	line_height: float,
	ic_id: int,
	pin_index: int,
):
	self.line_edit = line_edit
	self.signal_line = LA_signal_line.new(self, zoom_factor, line_color, line_height)
	self.ic_id = ic_id
	self.pin_index = pin_index
	

func _to_string() -> String:
	return "Parent ic's id = " + str(ic_id) + "; Pin_index = " + str(pin_index)	
	
