extends RefCounted
class_name ComponentSpecification

var name: String = ""
var num_pins: int = 0
var height: float = 0.0
var width: float = 0.0
var textures: Dictionary = {}
var pinSpecifications: Array = []
var details: Dictionary = {}
var content: String = ""

func initialize(name:String, num_pins:int, height:float, width:float, textures:Dictionary, pinSpecifications:Array, details:Dictionary, content:String = "")->void:
	self.name = name
	self.num_pins = num_pins
	self.width = width
	self.height = height
	self.textures = textures.duplicate(true)
	self.pinSpecifications = []
	for pin_spec in pinSpecifications:
		if pin_spec is PinSpecification:
			self.pinSpecifications.append(pin_spec.copy())
		else:
			self.pinSpecifications.append(pin_spec)
	self.details = details.duplicate(true)
	self.content = content

func initialize_from_json(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ).get_as_text()
	var parsed = JSON.parse_string(file)
	
	if parsed == null:
		InfoManager.write_error("Ошибка распознавания спецификации компонента: %s" % [path])
		return
	
	self.content = parsed.get("content", "")
	self.num_pins = parsed.num_pins
	self.width = parsed.width
	self.height = parsed.height
	#self.texture = parsed.texture
	self.name = parsed.name
	self.pinSpecifications = Array()
	self.details = parsed.get("details", {})
	
	var textures =  parsed.textures
	for t in textures:
		self.textures[t.name] = t.path
		
	var pins = parsed.pinSpecifications
	for pin in pins:
		var spec = PinSpecification.new()
		spec.initialize(pin.index, NetConstants.parse_direction(pin.direction), pin.position, pin.readable_name, pin.description, pin.dependencies)
		self.pinSpecifications.append(spec)
		
func set_details(details: Dictionary) -> void:
	self.details = details.duplicate(true)

func copy() -> ComponentSpecification:
	var new = ComponentSpecification.new()
	new.initialize(self.name, self.num_pins, self.height, self.width, self.textures, self.pinSpecifications, self.details, self.content)
	return new
