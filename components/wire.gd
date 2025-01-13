extends StaticBody2D
class_name Wire

var first_object
var second_object
var line
const pin_offset = 30
var hitbox: Array

var is_mouse_over = false
var has_hitbox = true
func initialize(first_object:Node2D, second_object:Node2D)->void:
	line.clear_points()

	line.add_point(first_object.global_position)
	line.add_point(first_object.global_position+get_pin_offset(first_object))
	line.add_point(Vector2((first_object.global_position+get_pin_offset(first_object)).x,(second_object.global_position+get_pin_offset(second_object)).y))
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
	if (GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode):
		self.modulate=Color(1,0,0,1)
	else:
		self.modulate=Color(1,1,1,1)
	first_object.modulate=Color(1,1,1,1)
	second_object.modulate=Color(1,1,1,1)
	first_object.toggle_output_highlight()
	second_object.toggle_output_highlight()
	is_mouse_over = false
var first_object_last_position = Vector2(0,0)
var second_object_last_position = Vector2(0,0)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float, force_update = false) -> void:
	# TODO: Render only if position of start|end nodes changed
	
	if first_object!=null and second_object!=null : # TODO: Notify WireManager about missing object
		if  (abs(first_object.global_position - first_object_last_position) >= Vector2.ONE * 1e-6 or abs(second_object.global_position - second_object_last_position) >= Vector2.ONE * 1e-6 or force_update):

			line.set_point_position(0, first_object.global_position)
			line.set_point_position(1, first_object.global_position+get_pin_offset(first_object))
			line.set_point_position(2,Vector2(line.get_point_position(1).x,line.get_point_position(3).y))
			line.set_point_position(line.get_point_count()-2,second_object.global_position+get_pin_offset(second_object))
			line.set_point_position(line.get_point_count()-1,second_object.global_position)
			if(has_hitbox):
				for i in range(0, line.points.size()-1):
					var shape = RectangleShape2D.new()
					shape.size = Vector2(3 if abs(line.points[i].x - line.points[i + 1].x)<0.3 else abs(line.points[i + 1].x - line.points[i].x),\
						3 if abs(line.points[i].y - line.points[i + 1].y)<0.3 else abs(line.points[i + 1].y - line.points[i].y))
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
	
		
		
func get_pin_offset(pin:Node2D):
	if(not pin is Pin): # Wire technically traces two Node2Ds, not two pins
		return Vector2.ZERO
	match pin.ic_position:
		"TOP":
			return Vector2.UP*pin_offset
		"BOTTOM":
			return Vector2.DOWN*pin_offset
		"LEFT":
			return Vector2.LEFT*pin_offset
		"RIGHT":
			return Vector2.RIGHT*pin_offset
		
func change_color():
	if (GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode):
		self.modulate=Color(1,0,0,1)
	else:
		self.modulate=Color(1,1,1,1)
