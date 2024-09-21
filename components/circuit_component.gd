extends StaticBody2D
class_name CircuitComponent

var is_dragged = false


var test_texture = preload("res://icon.svg")

var pins: Array
func initialize(spec: ComponentSpecification)->void:
	self.input_pickable = true
	var sprite = Sprite2D.new()
	var hitbox = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = test_texture.get_size()
	hitbox.shape = shape
	#var texture = load(spec.texture)
	sprite.texture = test_texture
	
	sprite.modulate = Color(0.0, 100.0, 0.0, 1.0)
	# Render texture and set height-width
	add_child(hitbox)
	add_child(sprite)
	initialize_pins(spec.pinSpecifications)

func initialize_pins(spec: Array)->void:
	for pin_spec in spec:
		var pin = Pin.new()
		pin.initialize(NetConstants.LEVEL.LEVEL_Z, pin_spec.direction, self)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_dragged && Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		self.global_position = get_global_mouse_position()
		

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		is_dragged = event.pressed


func _process_signal():
	pass
