extends StaticBody2D

var line: Line2D
var start: Vector2
var hitbox: CollisionShape2D
var is_dragged = false
var drag_offset = Vector2.ZERO
var now_disabled_drag = false
var is_mouse_over = false
var copy_offset: Vector2 = Vector2.ZERO
var is_tracking = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	line = get_node("Line2D")
	hitbox = get_node("CollisionShape2D")
	input_pickable = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_tracking and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var pos = get_global_mouse_position()
		var points = [Vector2(min(pos.x, start.x), min(pos.y, start.y)), Vector2(max(pos.x, start.x), min(pos.y, start.y)), Vector2(max(pos.x, start.x), max(pos.y, start.y)), Vector2(min(pos.x, start.x), max(pos.y, start.y))]
		hitbox.position = points[0]
		hitbox.shape.size = Vector2(points[2].x - points[0].x, points[2].y - points[0].y)
		hitbox.position += hitbox.shape.size / 2
		line.points = points
	elif is_tracking:
		is_tracking = false
		input_pickable = true
	is_tracking = is_tracking and GlobalSettings.is_selecting()
	if is_dragged && Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		get_node("/root/RootNode/Camera2D").lock_pan = true
		var offset = hitbox.position
		hitbox.position = get_global_mouse_position() + drag_offset
		offset = hitbox.position - offset
		for i in range(4):
			line.points[i] += offset
	elif not now_disabled_drag:
		self.is_dragged = false
		for obj in ComponentManager.obj_list.values():
			if obj.is_selected:
				obj.snap_to_grid()
				obj.is_dragged = false
		get_node("/root/RootNode/Camera2D").lock_pan = false
		now_disabled_drag = true

func start_tracking():
	start = get_global_mouse_position()
	visible = true
	is_tracking = true

func is_in(obj: CircuitComponent):
	return ((line.points[0].x <= obj.position.x) and ((obj.position.x + obj.hitbox.shape.size.x) <= line.points[2].x))\
	and ((line.points[0].y <= obj.position.y) and ((obj.position.y + obj.hitbox.shape.size.y) <= line.points[2].y))

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and GlobalSettings.is_normal_mode():
		get_node("/root/RootNode/Camera2D").lock_pan = true
		if(event.pressed):
			for obj in ComponentManager.obj_list.values():
				if obj.is_selected:
					obj.drag_offset = obj.global_position - get_global_mouse_position()
					obj.is_dragged = true
					var move_event = MoveEvent.new()
					move_event.initialize(obj.global_position, obj)
					HistoryBuffer.register_event(move_event)
			viewport.set_input_as_handled()
			drag_offset = hitbox.position - get_global_mouse_position()
			now_disabled_drag = false
		else:
			for obj in ComponentManager.obj_list.values():
				if obj.is_selected:
					obj.snap_to_grid()
					obj.is_dragged = false
			get_node("/root/RootNode/Camera2D").lock_pan = false
		is_dragged = event.pressed
	if Input.is_action_pressed("delete_component") and not GlobalSettings.disableGlobalInput:
		if self.is_mouse_over:
			for obj in ComponentManager.obj_list.values():
				if obj.is_selected:
					obj.delete_self()
			stop_selection()


func _on_mouse_entered() -> void:
	is_mouse_over = true


func _on_mouse_exited() -> void:
	is_mouse_over = false

func stop_selection():
	input_pickable = false
	self.visible = false
	hitbox.shape.size = Vector2(0, 0)
	for i in range(4):
		line.points[i] = Vector2(0, 0)
	is_tracking = false

func remember_copy_offset(pos: Vector2):
	copy_offset = hitbox.position - pos

func paste_copy_offset(pos: Vector2):
	var offset = hitbox.position
	hitbox.position = pos + copy_offset
	offset = hitbox.position - offset
	for i in range(4):
		line.points[i] += offset
