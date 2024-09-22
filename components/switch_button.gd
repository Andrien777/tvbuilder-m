extends CollisionShape2D
class_name SwitchButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var texture = preload("res://icon.svg")
var sprite: Sprite2D
func initialize()->void:
	sprite = Sprite2D.new()
	sprite.scale = Vector2(0.8,0.8)
	sprite.texture = texture
	sprite.modulate = Color(100, 0, 0, 1)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
