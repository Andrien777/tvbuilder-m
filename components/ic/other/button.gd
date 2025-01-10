extends CircuitComponent

class_name ICButton

var on = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
var button
func initialize(spec: ComponentSpecification, ic = null)->void:
	self.display_name_label = false # TODO: Move to spec?
	
	#self.sprite.texture = switch_texture
	#self.sprite.modulate = Color(0.5,0.5,0.5,1)
	self.scale = Vector2(1,1)
	button = ButtonButton.new()
	button.initialize(self)
	super.initialize(spec)
	button.position = sprite.texture.get_size() / 2
	add_child(button)
	
	if (GlobalSettings.CurrentGraphicsMode==DefaultGraphicsMode):
		self.sprite.modulate = Color(0,0,0,1)
	
func _process_signal():
	if on:
		pins[0].state = NetConstants.LEVEL.LEVEL_HIGH
	else:
		pins[0].state = NetConstants.LEVEL.LEVEL_LOW
func change_graphics_mode(mode):
	super.change_graphics_mode(mode)
	#super.update_pins(self.pins, self.hitbox.shape.size)
	#super.change_graphics_mode(mode)
	if(mode==LegacyGraphicsMode): 
		self.sprite.modulate = Color(1,1,1,1)
	else:
		self.sprite.modulate = Color(0,0,0,1)
	button.change_graphics_mode(mode)
	
