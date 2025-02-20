extends Node2D


var ic
var connections = {}
var continuous_update = false
@onready var grid_container = $Window/TabContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var pin_desc_container = $Window/TabContainer/ScrollContainer/PinDescriptionContainer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Window.close_requested.connect(close)
	$Window/TabContainer.set_tab_title(0,"Таблица соединений")
	$Window/TabContainer.set_tab_title(1,"Таблица ножек")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if continuous_update:
		get_connections(ic)
		#display_connections()
func display_connections():
	set_pins_description_table(ic)
	print(GlobalSettings.ShowSignalsInConnectionTable)
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

func set_pins_description_table(object):
	if is_instance_valid(object):
		var index_label = Label.new()
		var name_label = Label.new()
		var description_label = Label.new()
		var direction_label = Label.new()
		index_label.text = "Номер"
		name_label.text = "Имя"
		description_label.text = "Описание"
		direction_label.text = "Направление"
		pin_desc_container.add_child(index_label)
		pin_desc_container.add_child(VSeparator.new())
		pin_desc_container.add_child(name_label)
		pin_desc_container.add_child(VSeparator.new())
		pin_desc_container.add_child(description_label)
		pin_desc_container.add_child(VSeparator.new())
		pin_desc_container.add_child(direction_label)
		for pin in object.pins:
			index_label = Label.new()
			name_label = Label.new()
			description_label = Label.new()
			direction_label = Label.new()
			index_label.text = str(pin.index)
			name_label.text = pin.readable_name
			description_label.text = pin.description
			match pin.direction:
				NetConstants.DIRECTION.DIRECTION_INPUT:
					direction_label.text = "Ввод"
				NetConstants.DIRECTION.DIRECTION_OUTPUT:
					direction_label.text = "Вывод"
				NetConstants.DIRECTION.DIRECTION_INPUT_OUTPUT:
					direction_label.text = "Двунаправленный"
			pin_desc_container.add_child(index_label)
			pin_desc_container.add_child(VSeparator.new())
			pin_desc_container.add_child(name_label)
			pin_desc_container.add_child(VSeparator.new())
			pin_desc_container.add_child(description_label)
			pin_desc_container.add_child(VSeparator.new())
			pin_desc_container.add_child(direction_label)

func close():
	self.queue_free()


func _on_continuous_update_check_box_toggled(toggled_on: bool) -> void: # TODO: Implement continuous level updates
	continuous_update = toggled_on
