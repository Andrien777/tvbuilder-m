extends HistoryEvent

class_name BusCreationEvent

var name
var position
var connections: Dictionary # Array of Int (pin index), Pin pairs
var control_points:Array[Vector2]
var deleted_pins
var object:Bus
var id
var pins = []
func initialize(object:Bus):
	self.position = object.get_global_position()
	self.id = object.component.id
	self.control_points = object.control_points 
	self.deleted_pins = deleted_pins
	self.object = object
	#self.connections = object.connections
	for name in object.connections:
		for pin in object.connections[name]:
			pins.append([name, pin.index, pin.position])
	# This will require to populate the connections dict with Int -> Object pairs (self pin index -> other Pin object)
	# The issue is, we don`t know what is connected to a Pin now - only the WireManager knows that
	# Implementing this will mean implementing this functionality in WireManager class
	for wire in WireManager.wires: # Or we could just write some questionable code like this
		if wire.first_object in object.connection_pins:
			if connections.has(wire.first_object.index):
				connections[wire.first_object.index].append({"id": wire.second_object.parent.id,"index": wire.second_object.index, "control_points":wire.control_points, "reverse": false})
			else:
				connections[wire.first_object.index] = [{"id": wire.second_object.parent.id,"index": wire.second_object.index, "control_points":wire.control_points, "reverse": false}]
		elif wire.second_object in object.connection_pins:
			if connections.has(wire.second_object.index):
				connections[wire.second_object.index].append({"id": wire.first_object.parent.id,"index": wire.first_object.index, "control_points":wire.control_points, "reverse": true})
			else:
				connections[wire.second_object.index] = [{"id": wire.first_object.parent.id,"index": wire.first_object.index, "control_points":wire.control_points, "reverse": true}]

func redo():
	var bus = Bus.new()
	bus.initialize(control_points)
	WireManager.register_bus(bus)
	ComponentManager.change_id(bus.component, self.id)
	self.object = bus
	for p in pins:
		bus.add_connection(p[0], p[1], p[2])
	for key in connections:
		for conn in connections[key]:
			var other = ComponentManager.get_by_id(conn["id"])
			if conn["reverse"]:
				if not conn["control_points"].is_empty():
					var wire = WireManager._create_wire(other.pin(conn["index"]), bus.component.pin(key), conn["control_points"])
				else:
					WireManager._create_wire(other.pin(conn["index"]), bus.component.pin(key))
			else:
				if not conn["control_points"].is_empty():
					var wire = WireManager._create_wire(bus.component.pin(key), other.pin(conn["index"]), conn["control_points"])
				else:
					WireManager._create_wire(bus.component.pin(key), other.pin(conn["index"]))
	WireManager.force_update_wires()

func undo():
	if is_instance_valid(object):
		WireManager._delete_bus(object)
	else:
		var bus = ComponentManager.get_by_id(self.id)
		if is_instance_valid(bus):
			WireManager._delete_bus(bus)
		else:
			InfoManager.write_error("Не удалось отменить создание шины")
