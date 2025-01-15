extends Camera2D

var pressed_mmb = false
var mouse_offset = Vector2.ZERO
var prev_pos
#var grid_rect 
var lock_pan = false
var grid_sprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#grid_rect = get_node("../GridLayer/GridRect")
	grid_sprite = get_node("/root/RootNode/GridSprite")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#grid_rect.material.set_shader_parameter("position",position*zoom - delta_vec * zoom)
	if(GlobalSettings.disableGlobalInput):
		return
	if Input.is_action_just_pressed("ZoomUp") and get_window().has_focus():
		change_zoom(Vector2(0.1,0.1))
	elif Input.is_action_just_pressed("ZoomDown") and get_window().has_focus():
		if zoom.x > 0.1 and zoom.y > 0.1:
			change_zoom(Vector2(-0.1,-0.1))
	if Input.is_action_pressed("focus_camera") and get_window().has_focus() and not GlobalSettings.disableGlobalInput:
		move_to_centre()
	if not get_window().has_focus():
		pressed_mmb = false

func _physics_process(delta: float) -> void:
	if(GlobalSettings.disableGlobalInput):
		return
	if Input.is_action_pressed("pan_up"):
		position += Vector2.UP * 10
	if Input.is_action_pressed("pan_down"):
		position += Vector2.DOWN * 10
	if Input.is_action_pressed("pan_left"):
		position += Vector2.LEFT * 10
	if Input.is_action_pressed("pan_right"):
		position += Vector2.RIGHT * 10
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not lock_pan and not GlobalSettings.disableGlobalInput and get_node("/root/RootNode").get_window().has_focus() and not GlobalSettings.is_selecting:
		if pressed_mmb:
			position = mouse_offset - get_local_mouse_position()
			position = Vector2(int(position.x), int(position.y))
			prev_pos = position
		else:
			mouse_offset = position + get_local_mouse_position()
			prev_pos = position
	pressed_mmb = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	grid_sprite.offset = get_screen_center_position().snapped(Vector2(25, 25))

func move_to_centre():
	if not ComponentManager.obj_list.is_empty():
		var centre = Vector2.ZERO
		for obj: CircuitComponent in ComponentManager.obj_list.values():
			centre += obj.position + obj.hitbox.shape.size/2
		centre /= ComponentManager.obj_list.size()
		position = centre
		grid_sprite.offset = get_screen_center_position().snapped(Vector2(25, 25))

func change_zoom(delta: Vector2) -> void:
	var mouse_pos := get_global_mouse_position()
	zoom += delta
	var new_mouse_pos := get_global_mouse_position()
	#grid_rect.material.set_shader_parameter("scale", grid_rect.get_material().get_shader_parameter("scale") + delta)
	position += mouse_pos - new_mouse_pos
	position = Vector2(int(position.x), int(position.y))
	#grid_rect.material.set_shader_parameter("position",grid_rect.get_material().get_shader_parameter("position") + delta_vec * Vector2(-zoom.x/2,zoom.y/2))
