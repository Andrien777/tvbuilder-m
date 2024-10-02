extends StaticBody2D
class_name SwitchButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var texture = preload("res://icon.svg")
var sprite: Sprite2D
var parent: Switch
func initialize(parent: Switch)->void:
	self.input_pickable = true
	sprite = Sprite2D.new()
	self.scale = Vector2(0.3,0.3)
	sprite.texture = texture
	sprite.modulate = Color(100, 0, 0, 1)
	var hitbox = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = texture.get_size()
	hitbox.shape = shape
	add_child(sprite)
	add_child(hitbox)
	self.parent = parent
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		viewport.set_input_as_handled()
		parent.on = not parent.on
		if parent.on:
			sprite.modulate = Color(0, 100, 0, 1)
		else:
			sprite.modulate = Color(100, 0, 0, 1)
	
