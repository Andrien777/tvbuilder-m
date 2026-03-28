extends HistoryEvent
class_name WireDeletionEvent
var from
var to
var from_id
var to_id
var from_index
var to_index
var control_points

func _get_pin_or_null(component, index):
	if component == null or not is_instance_valid(component):
		return null
	if index <= 0 or index > component.pins.size():
		return null
	return component.pin(index)

func _has_saved_endpoints() -> bool:
	return typeof(from_id) == TYPE_INT and typeof(to_id) == TYPE_INT

func initialize(from, to, control_points = []):
	self.from = from
	self.to = to
	if is_instance_valid(from) and is_instance_valid(to): # For some reason this can happen
		self.from_id = from.parent.id
		self.to_id = to.parent.id
		self.from_index = from.index
		self.to_index = to.index
	else:
		InfoManager.write_error("Не удалось записать событие удаления провода")
	self.control_points = control_points.duplicate(true)
	
func undo():
	if is_instance_valid(from) and is_instance_valid(to):
		WireManager._create_wire(from, to, control_points)
	else:
		if not _has_saved_endpoints():
			return
		var from_ic = ComponentManager.get_by_id(from_id)
		var to_ic = ComponentManager.get_by_id(to_id)
		if from_ic == null or to_ic == null:
			return
		var from_pin = _get_pin_or_null(from_ic, from_index)
		var to_pin = _get_pin_or_null(to_ic, to_index)
		if from_pin == null or to_pin == null:
			return
		WireManager._create_wire(from_pin, to_pin, control_points)
func redo():
	if is_instance_valid(from) and is_instance_valid(to):
		WireManager._delete_wire_by_ends(from, to)
	else:
		if not _has_saved_endpoints():
			return
		var from_ic = ComponentManager.get_by_id(from_id)
		var to_ic = ComponentManager.get_by_id(to_id)
		if from_ic == null or to_ic == null:
			return
		var from_pin = _get_pin_or_null(from_ic, from_index)
		var to_pin = _get_pin_or_null(to_ic, to_index)
		if from_pin == null or to_pin == null:
			return
		WireManager._delete_wire_by_ends(from_pin, to_pin)
