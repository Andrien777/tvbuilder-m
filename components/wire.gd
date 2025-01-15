extends StaticBody2D
class_name Wire

var first_object
var second_object
var line
const pin_offset = 15
var hitbox: Array

var is_mouse_over = false
var has_hitbox = true
var is_dragged = false
var dragged_point_index = 0
var last_point_index = 4
var control_points: Array[Vector2]
var control_point_dragged_from
func initialize(first_object:Node2D, second_object:Node2D)->void:
	line.clear_points()

	line.add_point(first_object.global_position)
	line.add_point(first_object.global_position+get_pin_offset(first_object))
	line.add_point(line.get_point_position(1))
	line.add_point(Vector2((first_object.global_position+get_pin_offset(first_object)).x,(second_object.global_position+get_pin_offset(second_object)).y))
	line.add_point(second_object.global_position+get_pin_offset(second_object)) 
	line.add_point(second_object.global_position+get_pin_offset(second_object))
	line.add_point(second_object.global_position+get_pin_offset(second_object))
	line.add_point(second_object.global_position)
	
	
	if has_hitbox:
		for i in range(0, line.points.size() - 1):
			var shape = RectangleShape2D.new()
			shape.size = Vector2(3 if line.points[i].x == line.points[i + 1].x else abs(line.points[i + 1].x - line.points[i].x),\
				3 if line.points[i].y == line.points[i + 1].y else abs(line.points[i + 1].y - line.points[i].y))
			var hitbox_part = CollisionShape2D.new()
			hitbox_part.shape = shape
			hitbox_part.position = Vector2(0.5 * (line.points[i].x + line.points[i + 1].x),
				0.5 * (line.points[i].y + line.points[i + 1].y))
			add_child(hitbox_part)
			hitbox.append(hitbox_part)
	
	self.first_object = first_object
	self.second_object = second_object
	change_color()

func _init()->void:
	line = Line2D.new()
	#line.add_point(Vector2(0,0))
	#line.add_point(Vector2(500,500))
	line.width = 2
	line.antialiased = true
	add_child(line)
	self.input_pickable = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _mouse_enter() -> void:
	self.line.width = 4
	self.modulate=Color(0.7,0.7,0.7,1)
	first_object.modulate=Color(0.7,0.7,0.7,1)
	second_object.modulate=Color(0.7,0.7,0.7,1)
	is_mouse_over = true
func _mouse_exit() -> void:
	self.line.width = 2
	change_color()
	first_object.modulate=Color(1,1,1,1)
	second_object.modulate=Color(1,1,1,1)
	first_object.toggle_output_highlight()
	second_object.toggle_output_highlight()
	is_mouse_over = false
var first_object_last_position = Vector2(0,0)
var second_object_last_position = Vector2(0,0)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float, force_update = false) -> void:
	
	if first_object!=null and second_object!=null :
		if  (abs(first_object.global_position - first_object_last_position) >= Vector2.ONE * 1e-6 or abs(second_object.global_position - second_object_last_position) >= Vector2.ONE * 1e-6 or force_update):
			line.set_point_position(0, first_object.global_position)
			line.set_point_position(1, first_object.global_position+get_pin_offset(first_object))
			
			apply_advanced_routing()
			
			#min(line.get_point_position(2).x,line.get_point_position(line.get_point_count()-3).x)
			line.set_point_position(line.get_point_count()-4,line.get_point_position(line.get_point_count()-3))
			line.set_point_position(3,Vector2(line.get_point_position(2).x,line.get_point_position(line.get_point_count()-4).y))

			#line.set_point_position(line.get_point_count()-4,Vector2(line.get_point_position(line.get_point_count()-3).x,line.get_point_position(3).y))
			line.set_point_position(line.get_point_count()-2,second_object.global_position+get_pin_offset(second_object))
			line.set_point_position(line.get_point_count()-1,second_object.global_position)
			
			for point in control_points: # TODO: do something for every point
				line.set_point_position(dragged_point_index, Vector2(line.get_point_position(dragged_point_index-1).x,control_points[-1].y))
				line.set_point_position(dragged_point_index+1, control_points[-1])
				line.set_point_position(dragged_point_index+2, Vector2(control_points[-1].x,line.get_point_position(dragged_point_index+3).y))
			
			
			if(has_hitbox):
				for i in range(0, line.points.size()-1):
					var shape = RectangleShape2D.new()
					shape.size = Vector2(3 if abs(line.points[i].x - line.points[i + 1].x)<0.3 else abs(line.points[i + 1].x - line.points[i].x),\
						3 if abs(line.points[i].y - line.points[i + 1].y)<0.3 else abs(line.points[i + 1].y - line.points[i].y))
					if (shape.size.x!=3 and shape.size.y!=3):
						pass
					var hitbox_part
					if i < hitbox.size():
						hitbox_part = hitbox[i]
						hitbox_part.shape = shape
						hitbox_part.position = Vector2(0.5 * (line.points[i].x + line.points[i + 1].x),
							0.5 * (line.points[i].y + line.points[i + 1].y))
					else:
						hitbox_part = CollisionShape2D.new()
						hitbox_part.shape = shape
						add_child(hitbox_part)
						hitbox_part.position = Vector2(0.5 * (line.points[i].x + line.points[i + 1].x),
							0.5 * (line.points[i].y + line.points[i + 1].y))
						hitbox.append(hitbox_part)
		first_object_last_position = first_object.global_position
		second_object_last_position = second_object.global_position
	else:
		WireManager._delete_wire(self)
	if Input.is_action_pressed("delete_component") and self.is_mouse_over:
		Input.action_release("delete_component")
		first_object.modulate=Color(1,1,1,1)
		second_object.modulate=Color(1,1,1,1)
		WireManager._delete_wire(self)
		var event = WireDeletionEvent.new() # We are doing it there (and not in WireManager)
		# to prevent events creating from the HistoryEvent.undo() call 
		event.initialize(self.first_object, self.second_object)
		HistoryBuffer.register_event(event)
	if(is_dragged):
		control_points[-1] = snap_to_grid(get_global_mouse_position()) if GlobalSettings.WireSnap else get_global_mouse_position()
	for point in control_points: # TODO: do something for every point
		line.set_point_position(dragged_point_index, Vector2(line.get_point_position(dragged_point_index-1).x,control_points[-1].y))
		line.set_point_position(dragged_point_index+1, control_points[-1])
		line.set_point_position(dragged_point_index+2, Vector2(control_points[-1].x,line.get_point_position(dragged_point_index+3).y))
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		get_node("/root/RootNode/Camera2D").lock_pan = true
		if(event.pressed and control_points.is_empty()): # Limit to one control point for now
			add_control_point(get_global_mouse_position())
		is_dragged = event.pressed
		if (is_dragged==false):
			get_node("/root/RootNode/Camera2D").lock_pan = false
		else:
			control_point_dragged_from = get_global_mouse_position()
			
func _input(event: InputEvent) -> void: # This need to be like that because event won`t register in _input_event unless the mouse is on the wire
	if is_dragged and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed==false:
		is_dragged = false
		get_node("/root/RootNode/Camera2D").lock_pan = false
		_process(0.0,true) # Recalculate the hitbox
		var drag_event = ControlPointMoveEvent.new()
		drag_event.initialize(self,control_point_dragged_from, get_global_mouse_position())
		HistoryBuffer.register_event(drag_event)

func add_control_point(position):
	control_points.append(position)
	line.remove_point(last_point_index-1)
	last_point_index -=1
	line.add_point(Vector2(line.get_point_position(last_point_index-1).x,position.y), last_point_index)
	line.add_point(position, last_point_index+1)
	line.add_point(Vector2(position.x,line.get_point_position(last_point_index+4).y), last_point_index+2)
	dragged_point_index = last_point_index
	last_point_index+=3
	
	
func get_pin_offset(pin:Node2D):
	if(not pin is Pin): # Wire technically traces two Node2Ds, not two pins
		return Vector2.ZERO
	match pin.ic_position:
		"TOP":
			return Vector2.UP*(pin_offset + pin.index*GlobalSettings.PinIndexOffset)
		"BOTTOM":
			return Vector2.DOWN*(pin_offset+ pin.index*GlobalSettings.PinIndexOffset)
		"LEFT":
			return Vector2.LEFT*pin_offset
		"RIGHT":
			return Vector2.RIGHT*pin_offset
		
func change_color():
	if (GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode) and GlobalSettings.useDefaultWireColor:
		self.modulate=Color(1,0,0,1)
		GlobalSettings.wire_color = Color(1,0,0,1)
	elif GlobalSettings.useDefaultWireColor:
		self.modulate=Color(1,1,1,1)
		GlobalSettings.wire_color = Color(1,1,1,1)
	else:
		self.modulate = GlobalSettings.wire_color

func snap_to_grid(point): # TODO: Add wire snap to settings
	var snap_distance = 5
	var dx = int(point.x) % snap_distance if int(point.x) % snap_distance < (snap_distance - int(point.x) % snap_distance) else int(point.x) % snap_distance - snap_distance
	var dy = int(point.y) % snap_distance if int(point.y) % snap_distance < (snap_distance - int(point.y) % snap_distance) else int(point.y) % snap_distance - snap_distance
	dx += point.x - int(point.x)
	dy += point.y - int(point.y)
	point -= Vector2(dx, dy)
	return point

func apply_advanced_routing():
	if (first_object.global_position.y>second_object.global_position.y and first_object.ic_position=="BOTTOM") or (first_object.global_position.y<second_object.global_position.y and first_object.ic_position=="TOP"):
		if(second_object.global_position.x > first_object.global_position.x):
			line.set_point_position(2,first_object.global_position+get_pin_offset(first_object) # Go around through the left
			+ Vector2(-abs(first_object.global_position.x - first_object.parent.global_position.x) -20,0))
			#line.set_point_position(2,first_object.global_position+get_pin_offset(first_object) # Go around through the right
			#+ Vector2(abs(first_object.global_position.x - first_object.parent.global_position.x - first_object.parent.hitbox.shape.size.x) +20,0))
		else:
			line.set_point_position(2,first_object.global_position+get_pin_offset(first_object) + Vector2(-abs(first_object.global_position.x - first_object.parent.global_position.x) -20,0))
			#line.set_point_position(2,first_object.global_position+get_pin_offset(first_object) 
			#+ Vector2(abs(first_object.global_position.x - first_object.parent.global_position.x - first_object.parent.hitbox.shape.size.x) +20,0))
	else:
		line.set_point_position(2, line.get_point_position(1))
		
	# Additional Pin check is needed since second_object might be Node2D from wire_ghost_pointer
	if (second_object is Pin) and ((second_object.global_position.y>line.get_point_position(3).y and second_object.ic_position=="BOTTOM") or (second_object.global_position.y<line.get_point_position(3).y and second_object.ic_position=="TOP")):
		if (first_object.global_position.x > second_object.global_position.x):
			line.set_point_position(line.get_point_count()-3,second_object.global_position+get_pin_offset(second_object) # Go around through the left
			+ Vector2(-abs(second_object.global_position.x - second_object.parent.global_position.x) -20,0))
			#line.set_point_position(2,second_object.global_position+get_pin_offset(second_object) # Go around through the right
			#+ Vector2(abs(second_object.global_position.x - second_object.parent.global_position.x - second_object.parent.hitbox.shape.size.x) +20,0))
		else:
			line.set_point_position(line.get_point_count()-3,second_object.global_position+get_pin_offset(second_object) 
			+ Vector2(-abs(second_object.global_position.x - second_object.parent.global_position.x) -20,0))
			#line.set_point_position(2,second_object.global_position+get_pin_offset(second_object) 
			#+ Vector2(abs(second_object.global_position.x - second_object.parent.global_position.x - second_object.parent.hitbox.shape.size.x) +20,0))
	else:
		line.set_point_position(line.get_point_count()-3, line.get_point_position(line.get_point_count()-2))
				
