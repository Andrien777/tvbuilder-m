extends Node

class_name LASignalGroup

const Radix = preload("res://ui/logic_analyzer/Radix.gd").Radix

var signal_line: Control
var group_controller: LASignalGroupController

var signals: Array
var displayed_name: String:
	set = set_displayed_name
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
	)

	self.signal_line = signal_line
	self.radix = radix
	self.group_controller = group_controller
	self.signals = signals
	
func set_displayed_name(value: String):
	displayed_name = value
	group_controller.line_edit.text = displayed_name
	
