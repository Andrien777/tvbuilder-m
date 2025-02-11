extends Bus
class_name BusGhost
# Has only 2 control points
# Makes an interactive line between them
func _init()->void:
	line = Line2D.new()
	line.width = default_line_width
	line.antialiased = true
	add_child(line)
	# Remove the component part
	self.line.add_point(Vector2(0,0))
	self.line.add_point(Vector2(0,0))
	self.line.add_point(Vector2(0,0))
	self.control_points.append(Vector2(0,0))
	self.control_points.append(Vector2(0,0))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if self.visible:
		if not GlobalSettings.is_bus_mode():
			self.visible = false
		line.set_point_position(0, self.control_points[0])
		line.set_point_position(2, get_global_mouse_position())
		line.set_point_position(1,Vector2(line.get_point_position(0).x,line.get_point_position(2).y))

func update_hitbox():
	pass
