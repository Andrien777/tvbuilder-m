extends Camera2D

var pressed_mmb = false
var prev_pos
var grid_rect 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_rect = get_node("../GridLayer/GridRect")
	grid_rect.material.set_shader_parameter("position",Vector2(6, 5))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(GlobalSettings.disableGlobalInput):
		return
	if Input.is_action_just_pressed("ZoomUp"):
		change_zoom(Vector2(0.1,0.1))
		grid_rect.material.set_shader_parameter("scale", Vector2.ONE/zoom.x)
	elif Input.is_action_just_pressed("ZoomDown"):
		if zoom.x > 0.1 and zoom.y > 0.1:
			change_zoom(Vector2(-0.1,-0.1))
			grid_rect.material.set_shader_parameter("scale",  Vector2.ONE/zoom.x)

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("pan_up"):
		position += Vector2.UP * 10
		grid_rect.material.set_shader_parameter("position",grid_rect.get_material().get_shader_parameter("position") - Vector2.UP * 5 * zoom)
	if Input.is_action_pressed("pan_down"):
		position += Vector2.DOWN * 10
		grid_rect.material.set_shader_parameter("position",grid_rect.get_material().get_shader_parameter("position") - Vector2.DOWN * 5 * zoom)
	if Input.is_action_pressed("pan_left"):
		position += Vector2.LEFT * 10
		grid_rect.material.set_shader_parameter("position",grid_rect.get_material().get_shader_parameter("position") + Vector2.LEFT * 5 * zoom)
	if Input.is_action_pressed("pan_right"):
		position += Vector2.RIGHT * 10
		grid_rect.material.set_shader_parameter("position",grid_rect.get_material().get_shader_parameter("position") + Vector2.RIGHT * 5 * zoom)
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if pressed_mmb:
			var delta_vec = Input.get_last_mouse_velocity() * delta / zoom
			position -= delta_vec
			grid_rect.material.set_shader_parameter("position",grid_rect.get_material().get_shader_parameter("position") - delta_vec * Vector2(zoom.x / 1150, zoom.y / 650))
		prev_pos = get_global_mouse_position()
	
	pressed_mmb = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

func change_zoom(delta: Vector2) -> void:
	var mouse_pos := get_global_mouse_position()
	zoom += delta
	var new_mouse_pos := get_global_mouse_position()
	position += mouse_pos - new_mouse_pos
