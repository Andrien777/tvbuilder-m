extends CircuitComponent

class_name Keyboard

var on_rows = [0, 0, 0, 0]
var on_cols = [0, 0, 0]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
var button_arr = []
func initialize(spec: ComponentSpecification, ic = null)->void:
	self.display_name_label = false # TODO: Move to spec?
	
	#self.sprite.texture = switch_texture
	#self.sprite.modulate = Color(0.5,0.5,0.5,1)
	self.scale = Vector2(1,1)
	for i in range(4):
		var temp_arr = []
		for j in range(3):
			var button = ButtonButton.new()
			button.initialize(self, i, j)
			temp_arr.append(button)
		button_arr.append(temp_arr)
	super.initialize(spec)
	for i in range(4):
		for j in range(3):
			var button = button_arr[i][j]
			button.position = Vector2((sprite.texture.get_size().x / 3 - button.texture_up.get_size().x) + j * (sprite.texture.get_size().x / 3 - button.texture_up.get_size().x), 
			(sprite.texture.get_size().y / 4 - button.texture_up.get_size().y) + i * (sprite.texture.get_size().y / 4 - button.texture_up.get_size().y))
			add_child(button)
	
	if (GlobalSettings.CurrentGraphicsMode==DefaultGraphicsMode):
		self.sprite.modulate = Color(0,0,0,1)
	
func _process_signal():
	for i in range(4):
		if on_rows[i] > 0:
			pins[i].state = NetConstants.LEVEL.LEVEL_HIGH
		else:
			pins[i].state = NetConstants.LEVEL.LEVEL_LOW
	for i in range(3):
		if on_cols[i] > 0:
			pins[4 + i].state = NetConstants.LEVEL.LEVEL_HIGH
		else:
			pins[4 + i].state = NetConstants.LEVEL.LEVEL_LOW
func change_graphics_mode(mode):
	super.change_graphics_mode(mode)
	#super.update_pins(self.pins, self.hitbox.shape.size)
	#super.change_graphics_mode(mode)
	if(mode==LegacyGraphicsMode): 
		self.sprite.modulate = Color(1,1,1,1)
	else:
		self.sprite.modulate = Color(0,0,0,1)
	for i in range(4):
		for j in range(3):
			button_arr[i][j].change_graphics_mode(mode)
