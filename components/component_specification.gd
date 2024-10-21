extends RefCounted

class_name ComponentSpecification
func initialize(name:String, num_pins:int, height:float, width:float, texture:String, pinSpecifications:Array)->void:
	self.name = name
	self.num_pins = num_pins
	self.width = width
	self.height = height
	self.texture = texture
	self.pinSpecifications = pinSpecifications
func initialize_from_json(path: String) -> void:
	var json = JSON.new()
	var file = FileAccess.open(path, FileAccess.READ).get_as_text()
	var parsed = json.parse_string(file)
	if parsed != null:
		self.num_pins = parsed.num_pins
		self.width = parsed.width
		self.height = parsed.height
		self.texture = parsed.texture
		self.name = parsed.name
		self.pinSpecifications = Array()
		var pins = parsed.pinSpecifications
		for pin in pins:
			var spec = PinSpecification.new()
			spec.initialize(pin.index, NetConstants.parse_direction(pin.direction), pin.position, pin.readable_name, pin.description, pin.dependencies)
			self.pinSpecifications.append(spec)
	else:
		print("error")
		
var name: String
var num_pins: int
var width: float
var height: float
var texture: String
var pinSpecifications: Array
