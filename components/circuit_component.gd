extends StaticBody2D
class_name CircuitComponent

var is_dragged = false
var is_mouse_over = false
var now_disabled_drag = false

var drag_offset = Vector2(0,0)
var readable_name:String

var display_name_label = true
static var last_id = 0
var id
var test_texture = preload("res://components/ic/ic.png")
var height: float
var width: float
var texture: String
const side_padding = 10 # TODO: Move side_padding to spec?
var pins: Array
var ic_texture = null
var sprite = null
var hitbox
var name_label
func initialize(spec: ComponentSpecification, ic = null)->void: # Ic field holds saved state and is component-specific
	self.readable_name = spec.name
	self.input_pickable = true
	sprite = Sprite2D.new()
	sprite.centered = false
	hitbox = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	if (spec.texture!=""): 
		ic_texture = load(spec.texture)
	else:
		ic_texture = test_texture # TODO: Remove hardcoded names ASAP. We really need multiple textures. Its bad, i know
	var current_texture = ic_texture if (GlobalSettings.LegacyGraphics or spec.name=="Переключатель" or spec.name=="Светодиод") else test_texture
	shape.size = current_texture.get_size()
	sprite.texture = current_texture
	hitbox.shape = shape
	height = spec.height
	width = spec.width
	texture = spec.texture
	#var texture = load(spec.texture)
	#sprite.scale = Vector2(0.1,0.1)
	#sprite.modulate = Color(0.0, 0.0, 0.0, 1.0)
	# Render texture and set height-width
	#Label
	add_child(hitbox)
	add_child(sprite)
	initialize_pins(spec.pinSpecifications, shape.size)
	if(display_name_label):
		name_label = Label.new()
		name_label.position = Vector2(10,shape.size.y/2 - name_label.get_line_height()/2)
		#name_label.z_index = 2
		name_label.text = self.readable_name
		add_child(name_label)
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
				side_count["LEFT"]+=1
			"RIGHT":
				side_count["RIGHT"]+=1
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

		#pin.global_position = Vector2(200,200)
		pin.initialize(pin_spec, NetConstants.LEVEL.LEVEL_Z, self)
		
		pins.append(pin)
		add_child(pin)
	pins.sort_custom(pin_comparator)
	for pin in pins:
		match pin.ic_position:
			"TOP":
				pin.position = Vector2(side_padding+ 
				side_margin[pin.ic_position]*(side_count[pin.ic_position] - side_index[pin.ic_position]-1), # TODO: Please think of something better
				0)
				side_index[pin.ic_position]+=1
			"BOTTOM":
				pin.rotation_degrees =180
				pin.position = Vector2(side_padding+ 
				side_margin[pin.ic_position]*side_index[pin.ic_position], 
				ic_shape.y)
				side_index[pin.ic_position]+=1
			"LEFT":
				pin.rotation_degrees =270
				pin.position = Vector2(0, 
				side_padding+
				side_margin[pin.ic_position]*side_index[pin.ic_position])
				side_index[pin.ic_position]+=1	
			"RIGHT":
				pin.rotation_degrees =90
				pin.position = Vector2(ic_shape.x, 
				side_padding+
				side_margin[pin.ic_position]*(side_count[pin.ic_position] - side_index[pin.ic_position]-1))
				side_index[pin.ic_position]+=1
	for pin_spec in spec:
		if pin_spec.dependencies.is_empty() or pin_spec.direction == NetConstants.DIRECTION.DIRECTION_INPUT:
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
	elif not now_disabled_drag:
		self.is_dragged = false
		snap_to_grid()
		get_node("/root/RootNode/Camera2D").lock_pan = false
		now_disabled_drag = true
	if Input.is_action_pressed("delete_component") and self.is_mouse_over:
		Input.action_release("delete_component")
		ComponentManager.remove_object(self)
		queue_free()
		
var tween
func snap_to_grid():
	if tween:
		tween.kill()
	tween = create_tween()
	var dx = int(position.x) % 25 if int(position.x) % 25 < (25 - int(position.x) % 25) else int(position.x) % 25 - 25
	var dy = int(position.y) % 25 if int(position.y) % 25 < (25 - int(position.y) % 25) else int(position.y) % 25 - 25
	dx += position.x - int(position.x)
	dy += position.y - int(position.y)
	tween.tween_property(self,"position",position - Vector2(dx, dy),0.1).set_trans(Tween.TRANS_ELASTIC)
	
	
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if(event.pressed):
			get_node("/root/RootNode/Camera2D").lock_pan = true
			_lmb_action()
			drag_offset = global_position - get_global_mouse_position()
			viewport.set_input_as_handled()
			now_disabled_drag = false
		is_dragged = event.pressed
		if (is_dragged==false):
			snap_to_grid()
			get_node("/root/RootNode/Camera2D").lock_pan = false
			#position = position - Vector2(int(position.x)%25, int(position.y)%25)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if(event.pressed):
			_rmb_action()
func _lmb_action():
	pass
func _rmb_action():
	pass
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

func change_graphics_mode(mode:GlobalSettings.GraphicsMode):
	if (mode==GlobalSettings.GraphicsMode.Legacy): # TODO: Enum
		sprite.texture = ic_texture
	else:
		sprite.texture = test_texture
	var shape = RectangleShape2D.new()
	shape.size = sprite.texture.get_size()
	name_label.position = Vector2(10,shape.size.y/2 - name_label.get_line_height()/2)
	hitbox.shape = shape
	update_pins(self.pins, shape.size)

func update_pins(pins:Array, ic_shape:Vector2): 
	var side_count = {"TOP":0, "BOTTOM":0, "LEFT":0, "RIGHT":0}
	var side_margin = {"TOP":0, "BOTTOM":0, "LEFT":0, "RIGHT":0}
	for _pin in pins:
		match _pin.ic_position: # Could be just side_count[pin_spec]+=1
			"TOP":
				side_count["TOP"]+=1
			"BOTTOM":
				side_count["BOTTOM"]+=1
			"LEFT":
				side_count["LEFT"]+=1
			"RIGHT":
				side_count["RIGHT"]+=1
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
	for _pin in pins:
		_pin.change_graphics_mode(GlobalSettings.GraphicsMode.Legacy if GlobalSettings.LegacyGraphics else GlobalSettings.GraphicsMode.Default)
		var pin = _pin
		if(GlobalSettings.LegacyGraphics):
			pin.scale=Vector2(0.2,0.2)
		else:
			pin.scale=Vector2(0.2,0.4)
		match _pin.ic_position:
			"TOP":
				pin.position = Vector2(side_padding+ 
				side_margin[_pin.ic_position]*(side_count[_pin.ic_position] - side_index[_pin.ic_position]-1), # TODO: Please think of something better
				0)
				side_index[_pin.ic_position]+=1
			"BOTTOM":
				pin.rotation_degrees =180
				pin.position = Vector2(side_padding+ 
				side_margin[_pin.ic_position]*side_index[_pin.ic_position], 
				ic_shape.y)
				side_index[_pin.ic_position]+=1
			"LEFT":
				pin.rotation_degrees =270
				pin.position = Vector2(0 , 
				side_padding+
				side_margin[pin.ic_position]*side_index[pin.ic_position])
				side_index[pin.ic_position]+=1	
			"RIGHT":
				pin.rotation_degrees =90
				pin.position = Vector2(ic_shape.x, 
				side_padding+
				side_margin[pin.ic_position]*(side_count[pin.ic_position] - side_index[pin.ic_position]-1))
				side_index[pin.ic_position]+=1
