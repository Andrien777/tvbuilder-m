extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	if Input.is_action_just_pressed("ZoomUp"):
		change_zoom(Vector2(0.1,0.1))
	elif Input.is_action_just_pressed("ZoomDown"):
		if zoom.x > 0.1 and zoom.y > 0.1:
			change_zoom(Vector2(-0.1,-0.1))
	if Input.is_action_pressed("pan_up"):
		position += Vector2.UP * 10
	if Input.is_action_pressed("pan_down"):
		position += Vector2.DOWN * 10
	if Input.is_action_pressed("pan_left"):
		position += Vector2.LEFT * 10
	if Input.is_action_pressed("pan_right"):
		position += Vector2.RIGHT * 10

func change_zoom(delta: Vector2) -> void:
	var mouse_pos := get_global_mouse_position()
	zoom += delta
	var new_mouse_pos := get_global_mouse_position()
	position += mouse_pos - new_mouse_pos
