extends CircuitComponent
class_name LED
var sprite: Sprite2D
func initialize(spec: ComponentSpecification, comp_name: String)->void:
	super.initialize(spec, comp_name)
	self.scale = Vector2(0.5,1)
	sprite = Sprite2D.new()
	sprite.texture = test_texture
	sprite.modulate = Color(0, 100, 0, 0.2)
	add_child(sprite)

func _process(delta: float)->void:
	super._process(delta)
	if pins[0].state == NetConstants.LEVEL.LEVEL_HIGH:
		sprite.modulate = Color(0, 100, 0, 1)
	else:
		sprite.modulate = Color(0, 100, 0, 0.2)
