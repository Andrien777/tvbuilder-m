extends RefCounted

class_name PinSpecification

var index:int
var direction:NetConstants.DIRECTION
var position:String
var readable_name:String
var description: String
var dependencies: Array

func initialize(index: int, direction: NetConstants.DIRECTION, position: String, readable_name: String, description: String, dependencies: Array) -> void:
	self.index = index
	self.direction = direction
	self.position = position
	self.readable_name = readable_name
	self.description = description
	self.dependencies = dependencies
