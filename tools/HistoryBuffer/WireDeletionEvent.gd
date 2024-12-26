extends HistoryEvent
class_name WireDeletionEvent
var from
var to
var from_id
var to_id
var from_index
var to_index
func initialize(from, to):
	self.from = from
	self.to = to
	if is_instance_valid(from) and is_instance_valid(to): # For some reason this can happen
		self.from_id = from.parent.id
		self.to_id = to.parent.id
		self.from_index = from.index
		self.to_index = to.index
	
func undo():
	if is_instance_valid(from) and is_instance_valid(to):
		WireManager._create_wire(from, to)
	else:
		var from_ic = ComponentManager.get_by_id(from_id)
		var to_ic = ComponentManager.get_by_id(to_id)
		WireManager._create_wire(from_ic.pin(from_index), to_ic.pin(to_index))
func redo():
	if is_instance_valid(from) and is_instance_valid(to):
		WireManager._delete_wire_by_ends(from, to)
	else:
		var from_ic = ComponentManager.get_by_id(from_id)
		var to_ic = ComponentManager.get_by_id(to_id)
		WireManager._delete_wire_by_ends(from_ic.pin(from_index), to_ic.pin(to_index))
