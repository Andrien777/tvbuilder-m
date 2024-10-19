extends StaticBody2D
class_name SwitchButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var texture_up = preload("res://graphics/legacy/switch/sw_up.bmp")
var texture_down = preload("res://graphics/legacy/switch/sw_down.bmp")
var texture_default = preload("res://icon.svg")
var sprite: Sprite2D
var parent: Switch
func initialize(parent: Switch)->void:
	self.input_pickable = true
	sprite = Sprite2D.new()
	self.scale = Vector2(2,2) if GlobalSettings.LegacyGraphics else Vector2(0.3,0.3)
	sprite.texture = texture_up if GlobalSettings.LegacyGraphics else texture_default
	#sprite.modulate = Color(100, 0, 0, 1)
	var hitbox = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = sprite.texture.get_size()
	hitbox.shape = shape
	add_child(sprite)
	add_child(hitbox)
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
	if GlobalSettings.LegacyGraphics:
		sprite.set_texture(texture_up)
		#self.sprite.texture = texture_up
	else:
		sprite.modulate = Color(0, 100, 0, 1)
		
func set_off():
	if GlobalSettings.LegacyGraphics:
		sprite.set_texture(texture_down)
		#self.sprite.texture = texture_down
	else:
		sprite.modulate = Color(100, 0, 0, 1)
