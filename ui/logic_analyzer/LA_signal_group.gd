extends Node

class_name LASignalGroup

const Radix = preload("res://ui/logic_analyzer/Radix.gd").Radix

var signal_line: LASignalGroupLine
var group_controller: LASignalGroupController

var signals: Array
var radix: Radix

func _init(
	group_controller: LASignalGroupController,
	signals: Array,
	zoom_factor: float,
	height: float,
	radix: Radix
):
	var signal_line = LASignalGroupLine.new(
		zoom_factor, self, height
	)
	signal_line.custom_minimum_size = Vector2(0, height)
	
	group_controller.radix_changed.connect(
		func(radix):
			self.radix = radix
			signal_line.queue_redraw()
	)

	self.signal_line = signal_line
	self.radix = radix
	self.group_controller = group_controller
	self.signals = signals


func to_dict() -> Dictionary:
	var serialized_signals = signals.map(
		func(sig):
			return sig.to_dict()
	)
	return {
		"class_name": "LASignalGroup",
		"name": group_controller.line_edit.text,
		"radix": radix, 
		"signals": serialized_signals
	}
