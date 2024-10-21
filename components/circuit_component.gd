extends StaticBody2D
class_name CircuitComponent

var is_dragged = false
var is_mouse_over = false

var drag_offset = Vector2(0,0)
var readable_name:String

var display_name_label = true
static var last_id = 0
var id
var test_texture = preload("res://components/ic/ic.svg")
var height: float
var width: float
var texture: String
const side_padding = 20 # TODO: Move side_padding to spec?
var pins: Array
var ic_texture = null
var sprite = null
func initialize(spec: ComponentSpecification)->void:
	self.readable_name = spec.name
	self.input_pickable = true
	sprite = Sprite2D.new()
	var hitbox = CollisionShape2D.new()
	var shape = RectangleShape2D.new()

	if (spec.texture!=""):
		ic_texture = load(spec.texture)
	else:
		ic_texture = test_texture
	shape.size = ic_texture.get_size()
	sprite.texture = ic_texture
	hitbox.shape = shape
	height = spec.height
	width = spec.width
	texture = spec.texture
	#var texture = load(spec.texture)
	
	sprite.modulate = Color(0.0, 0.0, 0.0, 1.0)
	# Render texture and set height-width
	#Label
	if(display_name_label):
		var label = Label.new()
		label.position = self.position
		label.z_index = 2
		label.text = self.readable_name
		add_child(label)
	add_child(hitbox)
	add_child(sprite)
	initialize_pins(spec.pinSpecifications, shape.size)
	id = last_id
	last_id += 1
	ComponentManager.register_object(self)

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
				side_margin[k] = ic_shape.x/2
		else: # or vertically
			if side_count[k] != 1:
				side_margin[k] = (ic_shape.y-2*side_padding)/(side_count[k]-1)
			else:
				side_margin[k] = ic_shape.y/2


	var side_index = {"TOP":0, "BOTTOM":0, "LEFT":0, "RIGHT":0}
	for pin_spec in spec:
		var pin
		if pin_spec.direction == NetConstants.DIRECTION.DIRECTION_INPUT_OUTPUT:
			pin = IO_Pin.new()
		else:
			pin = Pin.new()
		if(GlobalSettings.LegacyGraphics):
			pin.scale=Vector2(0.2,0.2)
		else:
			pin.scale=Vector2(0.2,0.4)

		match pin_spec.position:
			"TOP":
				pin.position = Vector2(side_padding-ic_shape.x/2 + 
				side_margin[pin_spec.position]*side_index[pin_spec.position], 
				0-ic_shape.y/2)
				side_index[pin_spec.position]+=1
			"BOTTOM":
				pin.rotation_degrees =180
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
	pins.sort_custom(pin_comparator)
	for pin_spec in spec:
		if pin_spec.dependencies.is_empty():
			continue
		if pin_spec.dependencies[0] == -1:
			pins[pin_spec.index - 1].initialize_dependencies()
		else:
			for dep in pin_spec.dependencies:
				pins[pin_spec.index - 1].dependencies.append(pins[dep - 1])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_dragged && Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		self.global_position = get_global_mouse_position() + drag_offset
	else:
		self.is_dragged = false
	if Input.is_action_pressed("delete_component") and self.is_mouse_over:
		Input.action_release("delete_component")
		ComponentManager.remove_object(self)
		queue_free()
		
var tween
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if(event.pressed):
			drag_offset = global_position - get_global_mouse_position()
			viewport.set_input_as_handled()
		is_dragged = event.pressed
		if (is_dragged==false):
			if tween:
				tween.kill()
			tween = create_tween()
			tween.tween_property(self,"position",position - Vector2(int(position.x)%25, int(position.y)%25),0.1).set_trans(Tween.TRANS_ELASTIC)
			#position = position - Vector2(int(position.x)%25, int(position.y)%25)

func _process_signal():
	pass

func _mouse_enter() -> void:
	is_mouse_over = true
	
func _mouse_exit() -> void:
	is_mouse_over = false

static func pin_comparator(a,b):
	if a is Pin and b is Pin:
		return a.index < b.index
	else:
		return false

func to_json_object() -> Dictionary:
	return {
		"id": id,
		"name": readable_name,
		"position": position
	}
func pin(i:int):
	return self.pins[i-1]
