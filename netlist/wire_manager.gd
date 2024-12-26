extends Node2D
var wires: Array[Wire]
var first_wire_point = null
var second_wire_point = null
var timer: Timer
var wire_ghost_pointer = Node2D.new()
var wire_ghost = Wire.new()

func _init():
	wire_ghost.visible = false
	wire_ghost.line.modulate =Color(0.8,0.8,0.8,1)
	wire_ghost.has_hitbox = false
	add_child(wire_ghost)
	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.05
	timer.timeout.connect(force_update_wires)
	add_child(timer)

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
		if is_instance_valid(wire.second_object):
			(wire.second_object as Pin).state = NetConstants.LEVEL.LEVEL_Z
		wires.erase(wire)
		wire.queue_free()

func _delete_wire_by_ends(from, to): #Slow and questionable, but should work fine
	var wire_to_delete = null
	for wire in wires:
		if wire.first_object == from and wire.second_object == to or \
		wire.second_object == from and wire.first_object == to:
			wire_to_delete = wire
	
	NetlistClass.delete_connection(wire_to_delete.first_object, wire_to_delete.second_object)
	if is_instance_valid(wire_to_delete.first_object):
		(wire_to_delete.first_object as Pin).state = NetConstants.LEVEL.LEVEL_Z
	if is_instance_valid(wire_to_delete.second_object):
		(wire_to_delete.second_object as Pin).state = NetConstants.LEVEL.LEVEL_Z
	wires.erase(wire_to_delete)
	wire_to_delete.queue_free()

func _create_wire(first_object:Node2D, second_object:Node2D):
	if(first_object.parent is Switch):
		first_object.parent.label.text = second_object.readable_name # TODO: Delete this...
	
	if first_object==second_object:
		print("Соединение с самим собой")
		return
	var wire = Wire.new()
	wire.initialize(first_object,second_object)
	var first_pin = first_object as IO_Pin if first_object is IO_Pin else first_object as Pin
	var second_pin = second_object as IO_Pin if second_object is IO_Pin else second_object as Pin
	NetlistClass.add_connection(first_pin, second_pin)
	wires.append(wire)
	add_child(wire)
	return wire

func clear():
	for wire in wires:
		wire.queue_free()
	wires.clear()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


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
