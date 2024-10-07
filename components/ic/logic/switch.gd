extends CircuitComponent
class_name Switch

var on = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func initialize(spec: ComponentSpecification)->void:
	self.display_name_label = false # TODO: Move to spec?
	super.initialize(spec)
	#self.sprite.texture = switch_texture
	self.scale = Vector2(1,1)
	var button = SwitchButton.new()
	button.initialize(self)
	add_child(button)
	
func _process_signal():
	if on:
		pins[0].state = NetConstants.LEVEL.LEVEL_HIGH
	else:
		pins[0].state = NetConstants.LEVEL.LEVEL_LOW
