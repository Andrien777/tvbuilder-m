extends StaticBody2D
class_name CircuitComponent

var is_dragged = false


var test_texture = preload("res://icon.svg")
const side_padding = 20 # TODO: Move side_padding to spec?
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
	
	sprite.modulate = Color(0.0, 0.0, 0.0, 1.0)
	# Render texture and set height-width
	add_child(hitbox)
	add_child(sprite)
	initialize_pins(spec.pinSpecifications, test_texture.get_size())

func initialize_pins(spec: Array, ic_shape:Vector2)->void:
	var side_count = {"TOP":0, "BOTTOM":0, "LEFT":0, "RIGHT":0}
	var side_margin = {"TOP":0, "BOTTOM":0, "LEFT":0, "RIGHT":0}
	for pin_spec in spec:
		match pin_spec.position: # Could be just side_count[pin_spec]+=1
			"TOP":
				side_count["TOP"]+=1
			"BOTTOM":
				side_count["BOTTOM"]+=1
			"LEFT":
				side_count["BOTTOM"]+=1
			"RIGHT":
				side_count["BOTTOM"]+=1
	for k in side_count:
		if k=="TOP" or k=="BOTTOM": #if pins are spaced horizontally
			if side_count[k] != 1:
				side_margin[k] = (ic_shape.x-2*side_padding)/(side_count[k]-1)
			else:
				side_margin[k] = 0
		else: # or vertically
			if side_count[k] != 1:
				side_margin[k] = (ic_shape.y-2*side_padding)/(side_count[k]-1)
			else:
				side_margin[k] = 0


	var side_index = {"TOP":0, "BOTTOM":0, "LEFT":0, "RIGHT":0}
	for pin_spec in spec:
		var pin = Pin.new()
		pin.scale=Vector2(0.2,0.2)
		match pin_spec.position:
			"TOP":
				pin.position = Vector2(side_padding-ic_shape.x/2 + 
				side_margin[pin_spec.position]*side_index[pin_spec.position], 
				0-ic_shape.y/2)
				side_index[pin_spec.position]+=1
			"BOTTOM":
				pin.position = Vector2(side_padding-ic_shape.x/2 + 
				side_margin[pin_spec.position]*side_index[pin_spec.position], 
				0+ic_shape.y/2)
				side_index[pin_spec.position]+=1
			"LEFT":
				pin.position = Vector2(0-ic_shape.x/2 , 
				side_padding-ic_shape.y/2- 
				side_margin[pin_spec.position]*side_index[pin_spec.position])
				side_index[pin_spec.position]+=1	
			"RIGHT":
				pin.position = Vector2(0+ic_shape.x/2 , 
				side_padding-ic_shape.y/2-
				side_margin[pin_spec.position]*side_index[pin_spec.position])
				side_index[pin_spec.position]+=1	
		#pin.global_position = Vector2(200,200)
		pin.initialize(pin_spec, NetConstants.LEVEL.LEVEL_Z, self)
		
		pins.append(pin)
		add_child(pin)

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
	if event is InputEventMouseButton and event.pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		queue_free()


func _process_signal():
	pass
