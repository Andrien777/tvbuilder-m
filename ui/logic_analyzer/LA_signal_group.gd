extends Node

class_name LA_signal_group

signal line_changed
const Radix = preload("res://ui/logic_analyzer/Radix.gd").Radix

var signal_line: Control
var line_edit: LineEdit

var signals: Array
var is_open: bool = false
var radix: Radix

func _init(
	line_edit: LineEdit,
	signals: Array,
	zoom_factor: float,
	height: float
):
	var signal_line = LA_signal_group_line.new(
		zoom_factor, self, height
	)
	self.radix = Radix.BINARY
	signal_line.custom_minimum_size = Vector2(0, height - 4)
	
	self.signal_line = signal_line
	self.line_edit = line_edit
	self.signals = signals
