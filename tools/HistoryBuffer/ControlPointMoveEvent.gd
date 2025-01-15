extends HistoryEvent
class_name ControlPointMoveEvent
var from_id
var from_pin
var to_id
var to_pin
var from_pos
var to_pos
func initialize(wire, from, to):
	from_pos = from
	to_pos = to
	from_id = wire.first_object.parent.id
	from_pin = wire.first_object.index
	to_id = wire.second_object.parent.id
	to_pin = wire.second_object.index
	
	
func undo():
	var from = ComponentManager.get_by_id(from_id)
	var to = ComponentManager.get_by_id(to_id)
	if is_instance_valid(from) and is_instance_valid(to):
		var first_pin = from.pin(from_pin)
		var second_pin = to.pin(to_pin)
		if is_instance_valid(first_pin) and is_instance_valid(second_pin):
			var wire = WireManager.find_wire_by_ends(first_pin, second_pin)
			if is_instance_valid(wire):
				if(wire.control_points.is_empty()):
					wire.add_control_point(from_pos) # Should not happen
				else:
					wire.control_points[0] = from_pos
				WireManager.force_update_wires()

func redo():
	var from = ComponentManager.get_by_id(from_id)
	var to = ComponentManager.get_by_id(to_id)
	if is_instance_valid(from) and is_instance_valid(to):
		var first_pin = from.pin(from_pin)
		var second_pin = to.pin(to_pin)
		if is_instance_valid(first_pin) and is_instance_valid(second_pin):
			var wire = WireManager.find_wire_by_ends(first_pin, second_pin)
			if is_instance_valid(wire):
				if(wire.control_points.is_empty()):
					wire.add_control_point(to_pos) # Should not happen
				else:
					wire.control_points[0] = to_pos
				WireManager.force_update_wires()
