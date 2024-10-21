extends CircuitComponent
class_name LED
var sprite: Sprite2D
func initialize(spec: ComponentSpecification)->void:
	self.display_name_label = false
	super.initialize(spec)
	#self.scale = Vector2(0.5,0.5)
	sprite = Sprite2D.new()
	sprite.texture = ic_texture
	sprite.modulate = Color(0, 100, 0, 0.2)
	add_child(sprite)

func _process(delta: float)->void:
	super._process(delta)
	if pins[0].state == NetConstants.LEVEL.LEVEL_HIGH:
		sprite.modulate = Color(0, 100, 0, 1)
	else:
		sprite.modulate = Color(0, 100, 0, 0.2)
