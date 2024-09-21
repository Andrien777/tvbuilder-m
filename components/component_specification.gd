extends RefCounted

class_name ComponentSpecification
func initialize(num_pins:int, height:float, width:float, texture:String, pinSpecifications:Array)->void:
	self.num_pins = num_pins
	self.width = width
	self.height = height
	self.texture = texture
	self.pinSpecifications = pinSpecifications
var num_pins: int
var width: float
var height: float
var texture: String
var pinSpecifications: Array 
