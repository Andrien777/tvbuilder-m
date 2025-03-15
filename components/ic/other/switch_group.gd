extends CircuitComponent

class_name SwitchGroup

var on: Array = [false, false, false, false, false, false, false, false]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
var label # TODO: Delete this...
var button_arr = []
func initialize(spec: ComponentSpecification, ic = null)->void:
	self.display_name_label = false # TODO: Move to spec?
	
	#self.sprite.texture = switch_texture
	#self.sprite.modulate = Color(0.5,0.5,0.5,1)
	label = Label.new()
	label.position = self.position
	label.z_index = 2
	label.text = ""
	add_child(label)
	self.scale = Vector2(1,1)
	for i in range(8):
		var button = SwitchButton.new()
		button.initialize(self, i)
		button_arr.append(button)
	super.initialize(spec)
	for i in range(8):
		var button = button_arr[i]
		button.position = Vector2(sprite.texture.get_size().y / 2 + i * sprite.texture.get_size().y, sprite.texture.get_size().y / 2)
		add_child(button)
	
	if (GlobalSettings.CurrentGraphicsMode==DefaultGraphicsMode):
		self.sprite.modulate = Color(0,0,0,1)
	else:
		label.visible = false
	
func _process_signal():
	for i in range(8):
		if on[i]:
			pins[i].state = NetConstants.LEVEL.LEVEL_HIGH
		else:
			pins[i].state = NetConstants.LEVEL.LEVEL_LOW
func change_graphics_mode(mode):
	super.change_graphics_mode(mode)
	#super.update_pins(self.pins, self.hitbox.shape.size)
	#super.change_graphics_mode(mode)
	if(mode==LegacyGraphicsMode): 
		self.sprite.modulate = Color(1,1,1,1)
		label.visible =false
	else:
		self.sprite.modulate = Color(0,0,0,1)
		label.visible = true
	for i in range(8):
		button_arr[i].change_graphics_mode(mode)

static func pin_comparator(a,b):
	if a is Pin and b is Pin:
		return a.index < b.index
	else:
		return false
