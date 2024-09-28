extends StaticBody2D
class_name Pin

var pin_texture = preload("res://components/ic/pin.svg")

var index: int # Index on a chip
var state: NetConstants.LEVEL # Current state (low/high/z)
var direction: NetConstants.DIRECTION  # Input/output/io/disabled
var parent:Node2D
var ic_position: String
var readable_name: String
var description: String
var sprite_shape: Vector2
var dependencies: Array[Pin]
func initialize(spec: PinSpecification, state: NetConstants.LEVEL, parent: Node2D)->void:
	self.input_pickable = true
	self.state = state
	self.direction = spec.direction
	self.index = spec.index
	self.ic_position = spec.position
	self.readable_name = spec.readable_name
	self.description = spec.description
	self.parent = parent
	var sprite = Sprite2D.new()
	var hitbox = CollisionShape2D.new()
	sprite.texture = pin_texture
	var shape = RectangleShape2D.new()
	shape.size = pin_texture.get_size()
	#shape.size = Vector2(100,100) # TODO: Scale to sprite
	self.sprite_shape = shape.size
	hitbox.shape = shape
	add_child(sprite)
	add_child(hitbox)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func initialize_dependencies()->void:
	if self.direction == NetConstants.DIRECTION.DIRECTION_OUTPUT:
		for pin in self.parent.pins:
			if pin.direction == NetConstants.DIRECTION.DIRECTION_INPUT:
				dependencies.append(pin)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		WireManager.register_wire_point(self)
func _mouse_enter() -> void:
	self.modulate=Color(0.7,0.7,0.7,1)
	PopupManager.display_hint(readable_name+" " + str(index),description,self.global_position)
func _mouse_exit()->void:
	self.modulate=Color(1,1,1,1)
	PopupManager.hide_hint()

func low():
	return self.state==NetConstants.LEVEL.LEVEL_LOW

func high():
	return self.state==NetConstants.LEVEL.LEVEL_HIGH
	
func z():
	return self.state==NetConstants.LEVEL.LEVEL_Z
	
func high_or_z():
	return self.state==NetConstants.LEVEL.LEVEL_HIGH or self.state==NetConstants.LEVEL.LEVEL_Z
	
func low_or_z():
	return self.state==NetConstants.LEVEL.LEVEL_LOW or self.state==NetConstants.LEVEL.LEVEL_Z
	
	
func set_high():
	self.state = NetConstants.LEVEL.LEVEL_HIGH
func set_low():
	self.state = NetConstants.LEVEL.LEVEL_LOW
func set_z():
	self.state = NetConstants.LEVEL.LEVEL_Z
	
