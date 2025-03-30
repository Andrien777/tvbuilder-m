extends Node

class_name LASignal
	
var signal_controller: LASignalController
var signal_line: LASignalLine
var signal_points: Array = []  # Array of pairs time(ms) to level [float, NetConstants.LEVEL]
	
var ic_id: int
var pin_index: int

func _init(
	signal_controller: LASignalController,
	zoom_factor: float,
	line_color: Color,
	line_height: float,
	ic_id: int,
	pin_index: int,
):
	self.signal_controller = signal_controller
	self.signal_line = LASignalLine.new(self, zoom_factor, line_color, line_height)
	self.ic_id = ic_id
	self.pin_index = pin_index
	

func _to_string() -> String:
	return "Parent ic's id = " + str(ic_id) + "; Pin_index = " + str(pin_index)	
	
func to_dict() -> Dictionary:
	return {
		"class_name": "LASignal", 
		"ic_id": ic_id,
		"pin_index": pin_index,
		"name": signal_controller.line_edit.text,
		"signal_points": signal_points,
		"color": signal_line.color
	}
	
