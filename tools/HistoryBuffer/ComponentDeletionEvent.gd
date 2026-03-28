extends HistoryEvent

class_name ComponentDeletionEvent

var component_state: Dictionary = {}
var connections: Dictionary = {} # Array of Int (pin index), Pin pairs
var object
var id
var name = ""

func initialize(object):
	self.object = object
	self.component_state = object.to_json_object().duplicate(true)
	self.component_state["position"] = object.get_global_position()
	self.id = object.id
	self.component_state["id"] = self.id
	self.name = self.component_state.get("name", object.readable_name)
	# This will require to populate the connections dict with Int -> Object pairs (self pin index -> other Pin object)
	# The issue is, we don`t know what is connected to a Pin now - only the WireManager knows that
	# Implementing this will mean implementing this functionality in WireManager class
	for wire in WireManager.wires: # Or we could just write some questionable code like this
		if wire.first_object in object.pins:
			if connections.has(wire.first_object.index):
				connections[wire.first_object.index].append({
					"id": wire.second_object.parent.id,
					"index": wire.second_object.index,
					"control_points": wire.control_points.duplicate(true),
					"reverse": false
				})
			else:
				connections[wire.first_object.index] = [{
					"id": wire.second_object.parent.id,
					"index": wire.second_object.index,
					"control_points": wire.control_points.duplicate(true),
					"reverse": false
				}]
		elif wire.second_object in object.pins:
			if connections.has(wire.second_object.index):
				connections[wire.second_object.index].append({
					"id": wire.first_object.parent.id,
					"index": wire.first_object.index,
					"control_points": wire.control_points.duplicate(true),
					"reverse": true
				})
			else:
				connections[wire.second_object.index] = [{
					"id": wire.first_object.parent.id,
					"index": wire.first_object.index,
					"control_points": wire.control_points.duplicate(true),
					"reverse": true
				}]

func _get_pin_or_null(component, index):
	if component == null or not is_instance_valid(component):
		return null
	if index <= 0 or index > component.pins.size():
		return null
	return component.pin(index)

func undo():
	if component_state.is_empty():
		return
	var element = ComponentManager.create_component_from_state(component_state)
	if element == null:
		return
	ComponentManager.change_id(element, self.id)
	self.object = element
	ComponentManager.get_node("/root/RootNode").add_child(element) # TODO: idk thats stupid
	#ComponentManager.add_child(element)  # Thats even more stupid though
	for key in connections:
		for conn in connections[key]:
			var other = ComponentManager.get_by_id(conn["id"])
			if other == null:
				continue
			var self_pin = _get_pin_or_null(element, int(key))
			var other_pin = _get_pin_or_null(other, int(conn["index"]))
			if self_pin == null or other_pin == null:
				continue
			if conn["reverse"]:
				if not conn["control_points"].is_empty():
					WireManager._create_wire(other_pin, self_pin, conn["control_points"])
				else:
					WireManager._create_wire(other_pin, self_pin)
			else:
				if not conn["control_points"].is_empty():
					WireManager._create_wire(self_pin, other_pin, conn["control_points"])
				else:
					WireManager._create_wire(self_pin, other_pin)
	WireManager.force_update_wires()

func redo():
	if is_instance_valid(object):
		component_state["position"] = object.get_global_position()
		ComponentManager.add_to_deletion_queue(object)
	else:
		var existing_object = ComponentManager.get_by_id(self.id)
		if is_instance_valid(existing_object):
			component_state["position"] = existing_object.get_global_position()
			ComponentManager.add_to_deletion_queue(existing_object)
		else:
			InfoManager.write_error("Failed to redo component deletion")
