extends StaticBody2D
class_name Bus
var control_points:Array[Vector2] = []
var line
var is_mouse_over = false
var has_hitbox = true
var default_line_width = 6
var highlit_line_width = 12
var hitbox: Array

var connection_pins: Array[Pin]
var connections: Dictionary # ID (String) to Array[Pin] that are joined by this connection
var labels: Dictionary
var current_label
var current_pin
var last_pin_index = 0
var component
var deleted_pins = []
func _init()->void:
	line = Line2D.new()
	line.width = default_line_width
	line.antialiased = true
	add_child(line)
	self.input_pickable = true
	connection_pins = []
	
	component = BusComponent.new()
	component.bus = self
	component.readable_name = "Шина"
	
	ComponentManager.register_object(component)
	SaveManager.do_not_save(component.id)
func initialize(control_points: Array[Vector2]):
	for p in control_points:
		if(line.get_point_count()!=0): # if previous point exists
			line.add_point(Vector2(line.get_point_position(line.get_point_count()-1).x, p.y))
		self.control_points.append(p)
		line.add_point(p)
	change_color()
	update_hitbox()


# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	pass


func _mouse_enter() -> void:
	self.line.width = highlit_line_width
	self.line.modulate=GlobalSettings.highlightedBusColor
	is_mouse_over = true

func _mouse_exit() -> void:
	self.line.width = default_line_width
	change_color()
	is_mouse_over = false


func _process(delta: float) -> void:
	if Input.is_action_pressed("delete_component") and self.is_mouse_over and not GlobalSettings.disableGlobalInput:
		Input.action_release("delete_component")
		delete_self()

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not GlobalSettings.disableWireConnection:
		var pin = Pin.new()
		var spec = PinSpecification.new()
		spec.initialize(last_pin_index,NetConstants.DIRECTION.DIRECTION_INPUT,"TOP", "Шина", "Шина", [])
		# TODO: Init pin
		last_pin_index += 1
		
		var label = Label.new()
		pin.initialize(spec, NetConstants.LEVEL.LEVEL_Z, component)
		pin.global_position = get_global_mouse_position()
		pin.hide()
		WireManager.register_wire_point(pin)
		connection_pins.append(pin)
		label.global_position = pin.global_position
		label.add_theme_font_size_override("font_size",20)
		label.z_index = 2
		# TODO: Set label color to the label color variable, which does not exist yet

		get_node("/root/RootNode/UiCanvasLayer/GlobalInput").ask_for_input("Номер провода в шине", Callable(self, "register_connection"), false)
		current_label = label
		current_pin = pin
	#if event is InputEventMouseButton and event.pressed:
		#get_node("/root/RootNode/LogicAnalyzerWindow/RootVBoxContainer/ScrollContainer/SignalsHSplitContainer").add_signal(self)

func register_connection(name:String):
	current_label.text = name
	if connections.has(name) and not connections[name].is_empty():
		connections[name].append(current_pin)
		NetlistClass.add_connection(connections[name][-2], current_pin)
	else:
		connections[name] = [current_pin]
	labels[current_pin] = current_label
	self.component.pins.append(current_pin)
	add_child(current_pin)
	add_child(current_label)


func add_connection(name:String,index,  position:Vector2):
	var pin = Pin.new()
	var spec = PinSpecification.new()
	spec.initialize(index,NetConstants.DIRECTION.DIRECTION_INPUT,"TOP", "Шина", "Шина", [])
	last_pin_index  = max(last_pin_index, index)+1
	
	var label = Label.new()
	pin.initialize(spec, NetConstants.LEVEL.LEVEL_Z, component)
	pin.global_position = position
	pin.hide()
	connection_pins.append(pin)
	label.global_position = pin.global_position
	current_label = label
	current_pin = pin
	current_label.text = name
	label.global_position = pin.global_position
	label.add_theme_font_size_override("font_size",20)
	label.z_index = 2
	# TODO: Set label color to the label color variable, which does not exist yet
	register_connection(name)
	return current_pin
	
func add_point(point:Vector2):
	control_points.append(point)
	if(line.get_point_count()!=0): # if previous point exists
			line.add_point(Vector2(line.get_point_position(line.get_point_count()-1).x, point.y))
	line.add_point(point)
	update_hitbox()

func delete_connection(pin):
	for name in connections:
		if pin in connections[name]:
			for node in connections[name]: # Delete all connections to this pin
				NetlistClass.delete_connection(pin, node)
			self.component.pins.erase(pin)
			connection_pins.erase(pin)
			connections[name].erase(pin)
			deleted_pins.append([name, pin.index, pin.position]) # I already hate how this bus is implemented, so I dont really care
			
			if deleted_pins.size() > GlobalSettings.historyDepth: # Bus has to track its pin history to be able to restore them at request
				deleted_pins.pop_front()
				
			if is_instance_valid(labels[pin]):
				labels[pin].queue_free()
				labels.erase(pin)
			pin.queue_free()
			break

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
		if not hitbox.is_empty():
			component.hitbox = self.hitbox[0]

func change_color():
	if (GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode) and GlobalSettings.useDefaultWireColor:
		self.line.modulate=Color(1,0,0,1)
		GlobalSettings.bus_color = Color(1,0,0,1)
	elif GlobalSettings.useDefaultWireColor:
		self.line.modulate=Color(1,1,1,1)
		GlobalSettings.bus_color = Color(1,1,1,1)
	else:
		self.line.modulate = GlobalSettings.bus_color
	for label in labels.values():
		label.add_theme_color_override('font_color', GlobalSettings.label_color)

func delete_self():
	ComponentManager.add_to_deletion_queue(self.component)

func fully_delete():
		# Delete all connections from netlist
	for i in connection_pins:
		for j in connection_pins:
			NetlistClass.delete_connection(i, j) # Its sub-optimal. I don`t care
	for i in connection_pins:
		if is_instance_valid(i):
			i.queue_free() # Just to be safe
	ComponentManager.remove_object(component)
	WireManager._delete_bus(self)
	var event = BusDeletionEvent.new() 
	event.initialize(self)
	HistoryBuffer.register_event(event)
