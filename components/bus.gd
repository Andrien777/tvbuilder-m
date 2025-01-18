extends StaticBody2D
class_name Bus
var control_points = []
var line
var is_mouse_over = false
var has_hitbox = true
var default_line_width = 6
var highlit_line_width = 12
var hitbox: Array

var connection_pins: Array[Pin]
var connections: Dictionary # ID (String) to Array[Pin] that are joined by this connection

var current_label
var current_pin
func _init()->void:
	line = Line2D.new()
	line.width = default_line_width
	line.antialiased = true
	add_child(line)
	self.input_pickable = true
	connection_pins = []

func initialize(control_points: Array[Vector2]):
	for p in control_points:
		if(line.get_point_count()!=0): # if previous point exists
			line.add_point(Vector2(line.get_point_position(line.get_point_count()-1).x, p.y))
		line.add_point(p)
	update_hitbox()
		

# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	pass # Replace with function body.


func _mouse_enter() -> void:
	self.line.width = highlit_line_width
	self.modulate=Color(0.7,0.7,0.7,1)
	is_mouse_over = true

func _mouse_exit() -> void:
	self.line.width = default_line_width
	self.modulate=Color(1,1,1,1)
	is_mouse_over = false


func _process(delta: float) -> void:
	if Input.is_action_pressed("delete_component") and self.is_mouse_over and not GlobalSettings.disableGlobalInput:
		Input.action_release("delete_component")
		#TODO: Delete all connections from netlist
		WireManager._delete_bus(self)
		#var event = WireDeletionEvent.new() #TODO: Bus events
		#event.initialize(self.first_object, self.second_object)
		#HistoryBuffer.register_event(event)
		
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var pin = Pin.new()
		var spec = PinSpecification.new()
		spec.initialize(0,NetConstants.DIRECTION.DIRECTION_INPUT,"TOP", "Шина", "Шина", [])
		# TODO: Init pin
		var parent = CircuitComponent.new()
		var label = Label.new()
		parent.id = 0
		parent.global_position = get_global_mouse_position()
		#ComponentManager.register_object(parent) #TODO: Maybe???
		pin.initialize(spec, NetConstants.LEVEL.LEVEL_Z, parent)
		pin.global_position = get_global_mouse_position()
		pin.hide()
		WireManager.register_wire_point(pin)
		connection_pins.append(pin)
		label.global_position = pin.global_position
		get_node("/root/RootNode/UiCanvasLayer/GlobalInput").ask_for_input("Номер провода в шине", Callable(self, "register_connection"), false)
		#get_node("UiCanvasLayer/GlobalInput").ask_for_input("pls", Callable(self, "register_connection"))
		current_label = label
		current_pin = pin
	#if event is InputEventMouseButton and event.pressed:
		#get_node("/root/RootNode/LogicAnalyzerWindow/RootVBoxContainer/ScrollContainer/SignalsHSplitContainer").add_signal(self)
func register_connection(name):
	current_label.text = name
	if connections.has(name):
		connections[name].append(current_pin)
		NetlistClass.add_connection(connection_pins[-2], current_pin)
	else:
		connections[name] = [current_pin]
	add_child(current_pin)
	add_child(current_label)
func add_point(point:Vector2):
	control_points.append(point)
	if(line.get_point_count()!=0): # if previous point exists
			line.add_point(Vector2(line.get_point_position(line.get_point_count()-1).x, point.y))
	line.add_point(point)
	update_hitbox()
	
func update_hitbox():
	if(has_hitbox):
		for i in range(0, line.points.size()-1):
			var shape = RectangleShape2D.new()
			shape.size = Vector2(default_line_width*1.25 if abs(line.points[i].x - line.points[i + 1].x)<0.3 else abs(line.points[i + 1].x - line.points[i].x),\
				default_line_width*1.25 if abs(line.points[i].y - line.points[i + 1].y)<0.3 else abs(line.points[i + 1].y - line.points[i].y))
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
