extends Node2D

var grid_container
var ic
var connections = {}
var continuous_update = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_container = $Window/VBoxContainer/ScrollContainer/GridContainer
	$Window.close_requested.connect(close)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if continuous_update:
		get_connections(ic)
		#display_connections()
func display_connections():
	if GlobalSettings.ShowSignalsInConnectionTable:
		grid_container.columns = 4
		grid_container.get_node("SignalStateHeader").visible = true
	else:
		grid_container.columns = 3
		grid_container.get_node("SignalStateHeader").visible = false

	if is_instance_valid(ic):
		for pin_num in connections:
			for conn_point in connections[pin_num]:
				var pin_label = Label.new()
				pin_label.text = str(pin_num)+ " - "+ ic.pin(pin_num).readable_name
				#grid_container.add_child(pin_label)
				var target_ic = ComponentManager.get_by_id(conn_point.id)
				var target_ic_name_label = Label.new()
				target_ic_name_label.text = target_ic.readable_name
				var target_ic_pin_num_label = Label.new()
				target_ic_pin_num_label.text =str(conn_point.index) + " - "+ target_ic.pin(conn_point.index).readable_name
				grid_container.add_child(pin_label)
				grid_container.add_child(target_ic_name_label)
				grid_container.add_child(target_ic_pin_num_label)
				if GlobalSettings.ShowSignalsInConnectionTable:
					var signal_state_label = Label.new()
					signal_state_label.text = str(target_ic.pin(conn_point.index).state) if target_ic.pin(conn_point.index).state!=NetConstants.LEVEL.LEVEL_Z else "Z"
					grid_container.add_child(signal_state_label)
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


func _on_continuous_update_check_box_toggled(toggled_on: bool) -> void: # TODO: Implement continuous level updates
	continuous_update = toggled_on
