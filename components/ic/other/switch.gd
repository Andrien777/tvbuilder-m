extends CircuitComponent
class_name Switch

var on = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
var label # TODO: Delete this...
func initialize(spec: ComponentSpecification)->void:
	self.display_name_label = false # TODO: Move to spec?
	super.initialize(spec)
	#self.sprite.texture = switch_texture
	self.scale = Vector2(1,1)
	var button = SwitchButton.new()
	button.initialize(self)
	add_child(button)
	label = Label.new()
	label.position = self.position + Vector2(-20,-20)
	label.z_index = 2
	label.text = ""
	add_child(label)
	
func _process_signal():
	if on:
		pins[0].state = NetConstants.LEVEL.LEVEL_HIGH
	else:
		pins[0].state = NetConstants.LEVEL.LEVEL_LOW
