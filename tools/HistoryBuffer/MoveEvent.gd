extends HistoryEvent
class_name MoveEvent
var from
var to
var object
var id
func initialize(from, object):
	self.from = from
	self.to = to
	self.object = object
	self.id = object.id
func undo():
	if is_instance_valid(object):
		self.to = object.global_position
		object.global_position = self.from
		WireManager.force_update_wires_after_delay()
	else:
		object = ComponentManager.get_by_id(id) # Try id
		if is_instance_valid(object):
			self.to = object.global_position
			object.global_position = self.from
			WireManager.force_update_wires_after_delay()

func redo():
	if is_instance_valid(object):
		object.global_position = self.to
		WireManager.force_update_wires_after_delay()
	else:
		object = ComponentManager.get_by_id(id) # Try id
		if is_instance_valid(object):
			object.global_position = self.to
			WireManager.force_update_wires_after_delay()
