extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.pressed.connect(_button_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

var tree_visible = true
var tween
func _button_pressed():
	var tree = get_node("/root/RootNode/UiCanvasLayer/FunctionalUIContainer/ComponentTree")
	if tree_visible:
		if tween:
			tween.kill()
		tween = create_tween()
		tween.tween_property(tree,"scale",Vector2(0, 1),0.4).set_trans(Tween.TRANS_CIRC)
		tree_visible = false
	else:
		if tween:
			tween.kill()
		tween = create_tween()
		tween.tween_property(tree,"scale",Vector2(1, 1),0.4).set_trans(Tween.TRANS_ELASTIC)
		tree_visible = true
