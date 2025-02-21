extends StaticBody2D
class_name Pin

var pin_texture = preload("res://components/ic/pin2.png")
var legacy_pin_texture = preload("res://graphics/legacy/pins/legacy_pin.png")

var index: int # Index on a chip
var state: NetConstants.LEVEL # Current state (low/high/z)
var direction: NetConstants.DIRECTION  # Input/output/io/disabled
var parent: Node2D
var ic_position: String
var readable_name: String
var description: String
var sprite_shape: Vector2
var dependencies: Array[Pin]
var sprite
var is_tracked = false
func initialize(spec: PinSpecification, state: NetConstants.LEVEL, parent: Node2D)->void:
	self.input_pickable = true
	self.state = state
	self.direction = spec.direction
	self.index = spec.index
	self.ic_position = spec.position
	self.readable_name = spec.readable_name
	self.description = spec.description
	self.parent = parent
	
	sprite = Sprite2D.new()
	var hitbox = CollisionShape2D.new()
	if(GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode):
		sprite.texture = legacy_pin_texture
	else:
		sprite.texture = pin_texture
	var shape = RectangleShape2D.new()
	shape.size = pin_texture.get_size()
	#shape.size = Vector2(100,100) # TODO: Scale to sprite
	self.sprite_shape = shape.size
	hitbox.shape = shape
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = preload("res://shaders/shadow_pin.gdshader")
	sprite.z_index = -1
	add_child(sprite)
	add_child(hitbox)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func initialize_dependencies()->void:
	for pin in self.parent.pins:
		if pin.direction == NetConstants.DIRECTION.DIRECTION_INPUT:
			dependencies.append(pin)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (GlobalSettings.LevelHighlight):
		if(self.high):
			self.modulate = Color(0.3,1,1,1)
		else:
			self.modulate = Color(1,0.3,1,1)
	if is_tracked:
		self.modulate = GlobalSettings.highlightedLAPinsColor

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		WireManager.register_wire_point(self)
	if event is InputEventMouseButton and event.pressed:
		get_node("/root/RootNode/LogicAnalyzerWindow/RootVBoxContainer/ScrollContainer/SignalsHSplitContainer").add_signal(self)
		
		
func _mouse_enter() -> void:
	self.modulate=GlobalSettings.highlightedPinsColor
	PopupManager.display_hint("Пин: "+str(index)+ " | " + readable_name,description,self.global_position, self.direction)
	
func _mouse_exit()->void:
	if GlobalSettings.highlightOutputPins:
		if self.output():
			self.modulate = Color(1, 0, 0)
		else:
			self.modulate = Color(1, 1, 1)
	else:
		self.modulate = Color(1, 1, 1)
	PopupManager.hide_hint()


var low:
	get: return self.state==NetConstants.LEVEL.LEVEL_LOW
	
var high:
	get: return self.state==NetConstants.LEVEL.LEVEL_HIGH
	
var z:
	get: return self.state==NetConstants.LEVEL.LEVEL_Z
	
var high_or_z:
	get: return self.state==NetConstants.LEVEL.LEVEL_HIGH or self.state==NetConstants.LEVEL.LEVEL_Z
	
var low_or_z:
	get: return self.state==NetConstants.LEVEL.LEVEL_LOW or self.state==NetConstants.LEVEL.LEVEL_Z
	
	
func set_high():
	self.state = NetConstants.LEVEL.LEVEL_HIGH
func set_low():
	self.state = NetConstants.LEVEL.LEVEL_LOW
func set_z():
	self.state = NetConstants.LEVEL.LEVEL_Z
	

func output():
	return self.direction == NetConstants.DIRECTION.DIRECTION_OUTPUT
func input():
	return self.direction == NetConstants.DIRECTION.DIRECTION_INPUT

func change_graphics_mode(mode):
	if(mode==LegacyGraphicsMode): # Pins just have 2 graphics modes for now
		sprite.texture = legacy_pin_texture
	else:
		sprite.texture = pin_texture

func toggle_output_highlight():
	if GlobalSettings.highlightOutputPins:
		if self.output():
			self.modulate = Color(1, 0, 0)
	else:
		self.modulate = Color(1, 1, 1)
