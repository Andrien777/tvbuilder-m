extends HistoryEvent
class_name WireCreationEvent
var from
var to
var from_id
var to_id
var from_index
var to_index
var control_points
func initialize(object):
	if is_instance_valid(object):
		self.from = object.first_object
		self.to = object.second_object
		self.from_id = object.first_object.parent.id
		self.from_index = object.first_object.index
		self.to_id = object.second_object.parent.id
		self.to_index = object.second_object.index
		self.control_points = object.control_points

func undo():
	if is_instance_valid(from) and is_instance_valid(to):
		WireManager._delete_wire_by_ends(from, to)
	else:
		var from_ic = ComponentManager.get_by_id(from_id)
		var to_ic = ComponentManager.get_by_id(to_id)
		WireManager._delete_wire_by_ends(from_ic.pin(from_index), to_ic.pin(to_index))
	
func redo():
	if is_instance_valid(from) and is_instance_valid(to):
		WireManager._create_wire(from, to, control_points)
	else:
		var from_ic = ComponentManager.get_by_id(from_id)
		var to_ic = ComponentManager.get_by_id(to_id)
		WireManager._create_wire(from_ic.pin(from_index), to_ic.pin(to_index), control_points)
