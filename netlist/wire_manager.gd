extends Node2D
var wires: Array[Wire]
var first_wire_point = null
var second_wire_point = null

var wire_ghost_pointer = Node2D.new()
var wire_ghost = Wire.new()

func _init():
	wire_ghost.visible = false
	wire_ghost.line.modulate =Color(0.8,0.8,0.8,1)
	add_child(wire_ghost)

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
			_create_wire(first_wire_point, second_wire_point)
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
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	if(wire_ghost.visible):
		wire_ghost_pointer.position = get_global_mouse_position()
	

func get_json_list():
	pass
