extends StaticBody2D
class_name Pin

var pin_texture = preload("res://icon.svg")

var index: int # Index on a chip
var state: NetConstants.LEVEL # Current state (low/high/z)
var direction: NetConstants.DIRECTION  # Input/output/io/disabled
var parent:Node2D
var ic_position: String
var readable_name: String
var description: String

func initialize(spec: PinSpecification, state: NetConstants.LEVEL, parent: Node2D)->void:
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
	shape.size = Vector2(100,100) # TODO: Scale to sprite
	hitbox.shape = shape
	add_child(sprite)
	add_child(hitbox)
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
