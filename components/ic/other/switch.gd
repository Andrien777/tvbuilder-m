extends CircuitComponent
class_name Switch

var on = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
var label # TODO: Delete this...
var button
func initialize(spec: ComponentSpecification, ic = null)->void:
	self.display_name_label = false # TODO: Move to spec?
	super.initialize(spec)
	#self.sprite.texture = switch_texture
	#self.sprite.modulate = Color(0.5,0.5,0.5,1)
	
	self.scale = Vector2(1,1)
	button = SwitchButton.new()
	button.initialize(self)
	add_child(button)
	label = Label.new()
	label.position = self.position + Vector2(-20,-20)
	label.z_index = 2
	label.text = ""
	add_child(label)
	if (!GlobalSettings.LegacyGraphics):
		self.sprite.modulate = Color(0,0,0,1)
	else:
		label.visible = false
	
func _process_signal():
	if on:
		pins[0].state = NetConstants.LEVEL.LEVEL_HIGH
	else:
		pins[0].state = NetConstants.LEVEL.LEVEL_LOW
func change_graphics_mode(mode:GlobalSettings.GraphicsMode):
	super.update_pins(self.pins, self.hitbox.shape.size)
	#super.change_graphics_mode(mode)
	if(mode == GlobalSettings.GraphicsMode.Legacy): 
		self.sprite.modulate = Color(1,1,1,1)
		label.visible =false
	else:
		self.sprite.modulate = Color(0,0,0,1)
		label.visible = true
	button.change_graphics_mode(mode)
	
