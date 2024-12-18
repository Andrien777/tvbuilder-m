extends Camera2D

var pressed_mmb = false
var prev_pos
var grid_rect 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_rect = get_node("../GridLayer/GridRect")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(GlobalSettings.disableGlobalInput):
		return
	if Input.is_action_just_pressed("ZoomUp"):
		change_zoom(Vector2(0.1,0.1))
		grid_rect.material.set_shader_parameter("scale", Vector2.ONE/zoom)
	elif Input.is_action_just_pressed("ZoomDown"):
		if zoom.x > 0.1 and zoom.y > 0.1:
			change_zoom(Vector2(-0.1,-0.1))
			grid_rect.material.set_shader_parameter("scale",  Vector2.ONE/zoom)

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("pan_up"):
		position += Vector2.UP * 10
		grid_rect.material.set_shader_parameter("position",position)
	if Input.is_action_pressed("pan_down"):
		position += Vector2.DOWN * 10
		grid_rect.material.set_shader_parameter("position",position)
	if Input.is_action_pressed("pan_left"):
		position += Vector2.LEFT * 10
		grid_rect.material.set_shader_parameter("position",position)

	if Input.is_action_pressed("pan_right"):
		position += Vector2.RIGHT * 10
		grid_rect.material.set_shader_parameter("position",position)
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		if pressed_mmb:
			position -= Input.get_last_mouse_velocity() * delta / zoom
			Input.action_release("delete_component")
		prev_pos = get_global_mouse_position()
	
	pressed_mmb = Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)

func change_zoom(delta: Vector2) -> void:
	var mouse_pos := get_global_mouse_position()
	zoom += delta
	var new_mouse_pos := get_global_mouse_position()
	position += mouse_pos - new_mouse_pos
