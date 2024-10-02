extends CircuitComponent
class_name Switch

var on = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func initialize(spec: ComponentSpecification, comp_name: String)->void:
	super.initialize(spec, comp_name)
	self.scale = Vector2(0.5,1)
	var button = SwitchButton.new()
	button.initialize(self)
	add_child(button)
	
func _process_signal():
	if on:
		pins[0].state = NetConstants.LEVEL.LEVEL_HIGH
	else:
		pins[0].state = NetConstants.LEVEL.LEVEL_LOW
