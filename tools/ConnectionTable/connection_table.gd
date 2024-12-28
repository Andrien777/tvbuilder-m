extends Node2D

var grid_container
var ic
var connections = {}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_container = $Window/VBoxContainer/ScrollContainer/GridContainer
	$Window.close_requested.connect(close)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func display_connections():
	if is_instance_valid(ic):
		for pin_num in connections:
			for conn_point in connections[pin_num]:
				var pin_label = Label.new()
				pin_label.text = str(pin_num)+ " - "+ ic.pin(pin_num).readable_name
				grid_container.add_child(pin_label)
				var target_ic = ComponentManager.get_by_id(conn_point.id)
				var target_ic_name_label = Label.new()
				target_ic_name_label.text = target_ic.readable_name
				var target_ic_pin_num_label = Label.new()
				target_ic_pin_num_label.text =str(conn_point.index) + " - "+ target_ic.pin(conn_point.index).readable_name
				grid_container.add_child(pin_label)
				grid_container.add_child(target_ic_name_label)
				grid_container.add_child(target_ic_pin_num_label)
func get_connections(object):
	if is_instance_valid(object):
		for wire in WireManager.wires: # Or we could just write some questionable code like this
			if wire.first_object in object.pins:
				if connections.has(wire.first_object.index):
					connections[wire.first_object.index].append({"id": wire.second_object.parent.id,"index": wire.second_object.index})
				else:
					connections[wire.first_object.index] = [{"id": wire.second_object.parent.id,"index": wire.second_object.index}]
			elif wire.second_object in object.pins:
				if connections.has(wire.second_object.index):
					connections[wire.second_object.index].append({"id": wire.first_object.parent.id,"index": wire.first_object.index})
				else:
					connections[wire.second_object.index] = [{"id": wire.first_object.parent.id,"index": wire.first_object.index}]

func close():
	self.queue_free()
