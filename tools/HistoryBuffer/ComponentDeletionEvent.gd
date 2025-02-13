extends HistoryEvent

class_name ComponentDeletionEvent

var name
var position
var connections: Dictionary # Array of Int (pin index), Pin pairs
var object
var id

func initialize(object):
	self.name=  object.readable_name
	self.position = object.get_global_position()
	self.id = object.id
	# This will require to populate the connections dict with Int -> Object pairs (self pin index -> other Pin object)
	# The issue is, we don`t know what is connected to a Pin now - only the WireManager knows that
	# Implementing this will mean implementing this functionality in WireManager class
	for wire in WireManager.wires: # Or we could just write some questionable code like this
		if wire.first_object in object.pins:
			if connections.has(wire.first_object.index):
				connections[wire.first_object.index].append({"id": wire.second_object.parent.id,"index": wire.second_object.index, "control_points":wire.control_points, "reverse": false})
			else:
				connections[wire.first_object.index] = [{"id": wire.second_object.parent.id,"index": wire.second_object.index, "control_points":wire.control_points, "reverse": false}]
		elif wire.second_object in object.pins:
			if connections.has(wire.second_object.index):
				connections[wire.second_object.index].append({"id": wire.first_object.parent.id,"index": wire.first_object.index, "control_points":wire.control_points, "reverse": true})
			else:
				connections[wire.second_object.index] = [{"id": wire.first_object.parent.id,"index": wire.first_object.index, "control_points":wire.control_points, "reverse": true}]

func undo():
	if name == null: return
	var spec = ComponentSpecification.new()
	spec.initialize_from_json( ComponentManager.get_config_path_by_name(name) )
	var element: CircuitComponent = load( ComponentManager.get_class_path_by_name(name) ).new()
	element.initialize(spec)
	element.position = position
	ComponentManager.change_id(element, self.id)
	self.object = element
	ComponentManager.get_node("/root/RootNode").add_child(element) # TODO: idk thats stupid
	#ComponentManager.add_child(element)  # Thats even more stupid though
	for key in connections:
		for conn in connections[key]:
			var other = ComponentManager.get_by_id(conn["id"])
			if conn["reverse"]:
				if not conn["control_points"].is_empty():
					var wire = WireManager._create_wire(other.pin(conn["index"]), element.pin(key), conn["control_points"])
				else:
					WireManager._create_wire(other.pin(conn["index"]), element.pin(key))
			else:
				if not conn["control_points"].is_empty():
					var wire = WireManager._create_wire(element.pin(key), other.pin(conn["index"]), conn["control_points"])
				else:
					WireManager._create_wire(element.pin(key), other.pin(conn["index"]))
	WireManager.force_update_wires()

func redo():
	if is_instance_valid(object):
		self.position = object.get_global_position()
		ComponentManager.add_to_deletion_queue(object)
	else:
		var _object = ComponentManager.get_by_id(self.id)
		if is_instance_valid(_object):
			ComponentManager.add_to_deletion_queue(_object)
		else:
			InfoManager.write_error("Не удалось отменить создание компонента")
