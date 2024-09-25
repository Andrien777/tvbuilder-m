extends RefCounted

class_name NetlistNode

var neighbours: Array[NetlistNode]
var pin: Pin

func initialize(pin: Pin) -> void:
	self.pin = pin
