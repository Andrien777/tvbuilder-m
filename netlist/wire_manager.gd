extends Node
var wires: Array[Wire]
var first_wire_point = null
var second_wire_point = null
func register_wire_point(object:Node2D):
	if first_wire_point == null:
		first_wire_point =object
	elif second_wire_point==null:
		# TODO: Check if creation is possible
		second_wire_point = object
		_create_wire(first_wire_point, second_wire_point)
		first_wire_point = null
		second_wire_point = null

func _delete_wire(wire):
	if wire in wires:
		NetlistClass.delete_connection(wire.first_object, wire.second_object)
		wires.erase(wire)
		wire.queue_free()

func _create_wire(first_object:Node2D, second_object:Node2D):
	var wire = Wire.new()
	wire.initialize(first_object,second_object)
	NetlistClass.add_connection(first_object as Pin, second_object as Pin)
	wires.append(wire)
	add_child(wire)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
