extends StaticBody2D
class_name SwitchButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var texture_up = preload("res://graphics/legacy/switch/sw_up.png")
var texture_down = preload("res://graphics/legacy/switch/sw_down.png")
var texture_default = preload("res://icon.svg")
var sprite: Sprite2D
var parent: Switch
var button_hitbox
func initialize(parent: Switch)->void:
	self.input_pickable = true
	sprite = Sprite2D.new()
	self.scale = Vector2(1,1) if GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode else Vector2(1,1)
	sprite.texture = texture_down if GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode else texture_default
	if(GlobalSettings.CurrentGraphicsMode==DefaultGraphicsMode):
		sprite.modulate = Color(100, 0, 0, 1)
		sprite.scale = Vector2(10, 10)
	button_hitbox = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = sprite.texture.get_size()
	button_hitbox.shape = shape
	add_child(sprite)
	add_child(button_hitbox)
	self.parent = parent
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		viewport.set_input_as_handled()
		parent.on = not parent.on
		if parent.on:
			set_on()
		else:
			set_off()
	
func set_on():
	if GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode:
		sprite.set_texture(texture_up)
		#self.sprite.texture = texture_up
	else:
		sprite.modulate = Color(0, 100, 0, 1)
		
func set_off():
	if GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode:
		sprite.set_texture(texture_down)
		#self.sprite.texture = texture_down
	else:
		sprite.modulate = Color(100, 0, 0, 1)

func change_graphics_mode(mode):
	#super.change_graphics_mode(mode) 
	self.scale = Vector2(1,1) if mode==LegacyGraphicsMode else Vector2(1,1)
	
	if(LegacyGraphicsMode):
		sprite.scale = Vector2(1, 1) 
		sprite.modulate = Color(1,1,1,1)
		sprite.set_texture(texture_down)
	else:
		sprite.scale = Vector2(10, 10) 
		sprite.set_texture(texture_default)
		sprite.modulate = Color(0,0,0,1)
	var shape = RectangleShape2D.new()
	shape.size = sprite.texture.get_size()
	button_hitbox.shape = shape
	if parent.on:
		set_on()
	else:
		set_off()
	
