extends Node2D
var wires: Array[Wire]
var buses: Array[Bus]
var current_bus = null
var first_wire_point = null
var second_wire_point = null
var timer: Timer
var wire_ghost_pointer = Node2D.new()
var wire_ghost = Wire.new()
var bus_ghost = BusGhost.new()

func _init():
	wire_ghost.visible = false
	wire_ghost.line.modulate =Color(0.8,0.8,0.8,1)
	wire_ghost.has_hitbox = false
	add_child(wire_ghost)
	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.1
	timer.timeout.connect(force_update_wires)
	add_child(timer)
	bus_ghost.visible =false
	bus_ghost.line.modulate =Color(0.8,0.8,0.8,1)
	bus_ghost.has_hitbox = false
	add_child(bus_ghost)
func stop_wire_creation():
	wire_ghost.visible = false
	first_wire_point = null
	second_wire_point = null

func register_wire_point(object:Node2D):
	if first_wire_point == null:
		first_wire_point =object
		wire_ghost_pointer.position = get_global_mouse_position()
		wire_ghost.initialize(object, wire_ghost_pointer)
		wire_ghost.visible = true
	elif second_wire_point==null:
		wire_ghost.visible = false
		second_wire_point = object
		if Input.is_key_pressed(KEY_SHIFT):
			for wire in wires:
				print(wire)
				if(wire.first_object==first_wire_point and wire.second_object==second_wire_point) or (wire.first_object==second_wire_point and wire.second_object==first_wire_point):
					_delete_wire(wire)
		else:
			# TODO: Check if creation is possible
			var event = WireCreationEvent.new()
			event.initialize(_create_wire(first_wire_point, second_wire_point)) # TODO: Kind of ugly side effect use
			HistoryBuffer.register_event(event)
			
		first_wire_point = null
		second_wire_point = null

func _delete_wire(wire):
	if wire in wires:
		NetlistClass.delete_connection(wire.first_object, wire.second_object)
		if is_instance_valid(wire.first_object):
			(wire.first_object as Pin).state = NetConstants.LEVEL.LEVEL_Z
			if(wire.first_object.parent is BusComponent): # TODO: Maybe this should be a signal going to the pin
				wire.first_object.parent.delete_connection(wire.first_object)
		if is_instance_valid(wire.second_object):
			(wire.second_object as Pin).state = NetConstants.LEVEL.LEVEL_Z
			if(wire.second_object.parent is BusComponent):
				wire.second_object.parent.delete_connection(wire.second_object)
		wires.erase(wire)
		if GlobalSettings.showLastWire:
			if not wires.is_empty():
				wires.back().visible = true
				wires.back().input_pickable = true
		wire.queue_free()
		
func find_wire_by_ends(from, to):
	var res_wire
	for wire in wires:
		if wire.first_object == from and wire.second_object == to or \
		wire.second_object == from and wire.first_object == to:
			res_wire = wire
	return res_wire
	
func _delete_wire_by_ends(from, to): #Slow and questionable, but should work fine
	var wire_to_delete = find_wire_by_ends(from, to)
	#for wire in wires:
		#if wire.first_object == from and wire.second_object == to or \
		#wire.second_object == from and wire.first_object == to:
			#wire_to_delete = wire

	NetlistClass.delete_connection(wire_to_delete.first_object, wire_to_delete.second_object)
	if is_instance_valid(wire_to_delete.first_object):
		(wire_to_delete.first_object as Pin).state = NetConstants.LEVEL.LEVEL_Z
		if(wire_to_delete.first_object.parent is BusComponent): # TODO: Maybe this should be a signal going to the pin
			wire_to_delete.first_object.parent.delete_connection(wire_to_delete.first_object)
	if is_instance_valid(wire_to_delete.second_object):
		(wire_to_delete.second_object as Pin).state = NetConstants.LEVEL.LEVEL_Z
		if(wire_to_delete.second_object.parent is BusComponent):
			wire_to_delete.second_object.parent.delete_connection(wire_to_delete.second_object)
	wires.erase(wire_to_delete)
	if GlobalSettings.showLastWire:
		if not wires.is_empty():
			wires.back().visible = true
			wires.back().input_pickable = true
	wire_to_delete.queue_free()

func _create_wire(first_object:Node2D, second_object:Node2D, control_points = []):
	if(first_object.parent is Switch):
		first_object.parent.label.text = second_object.readable_name # TODO: Delete this...
	
	var found = false
	for wire in wires:
		if wire.first_object == first_object and wire.second_object == second_object or\
		 wire.first_object == second_object and wire.second_object == first_object:
			found = true
			break
	if found:
		return
	if first_object==second_object:
		print("Соединение с самим собой")
		return
	var wire = Wire.new()
	wire.initialize(first_object,second_object)
	var first_pin = first_object as IO_Pin if first_object is IO_Pin else first_object as Pin
	var second_pin = second_object as IO_Pin if second_object is IO_Pin else second_object as Pin
	NetlistClass.add_connection(first_pin, second_pin)

	if not control_points.is_empty():
		for p in control_points:
			wire.add_control_point(p)

	if GlobalSettings.showLastWire:
		if not wires.is_empty():
			wires.back().visible = false
			wires.back().input_pickable = false

	wires.append(wire)
	add_child(wire)
	return wire

func clear():
	for wire in wires:
		wire.queue_free()
	wires.clear()
	for bus in buses:
		bus.queue_free()
	buses.clear()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func toggle_last_wire_visible():
	if GlobalSettings.showLastWire:
		for wire in wires:
			wire.visible = false
			wire.input_pickable = false
		if not wires.is_empty():
			wires.back().visible = true
			wires.back().input_pickable = true
	else:
		for wire in wires:
			wire.visible = true
			wire.input_pickable = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(wire_ghost.visible):
		wire_ghost_pointer.position = get_global_mouse_position()
	

func get_json_list():
	pass

func force_update_wires_after_delay():
	if timer.is_stopped():
		timer.start()
	else:
		timer.stop()
		timer.start()

func force_update_wires():
	for wire in wires:
		wire._process(0.0,true)
		
func _create_bus(initial_point = Vector2(0,0)):
	var bus = Bus.new()
	bus.initialize([initial_point])
	buses.append(bus)
	add_child(bus)
	return bus
	
func register_bus(bus:Bus):
	buses.append(bus)
	add_child(bus)

func register_bus_point(point:Vector2):
	if !current_bus:
		current_bus = _create_bus(point)
		bus_ghost.control_points[0] = point
		bus_ghost.visible = true
	else:
		current_bus.add_point(point)
		bus_ghost.control_points[0] = point
	
func _delete_bus(bus):
	if bus in buses:
		buses.erase(bus)
		bus.queue_free()

func buses_to_json():
	var json = []
	for bus in buses:
		json.append(bus.component.to_json_object())
	return json

func finish_current_bus():
	current_bus = null
	bus_ghost.visible = false
