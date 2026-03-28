extends Node

var buffer: Array[CopiedItem] = []
var id_change_lut: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func copy(mouse_pos: Vector2) -> Vector2:
	buffer.clear()
	id_change_lut.clear()
	var centre = Vector2.ZERO
	var counter = 0
	for obj: CircuitComponent in ComponentManager.obj_list.values():
		if obj.is_selected:
			centre += obj.position + obj.hitbox.shape.size/2
			counter += 1
	if counter > 0:
		centre /= counter
	else:
		centre = mouse_pos
	for obj in ComponentManager.obj_list.values():
		if obj.is_selected:
			var item = CopiedItem.new()
			item.copy(obj, centre)
			buffer.append(item)
			id_change_lut[obj.id] = -1
	if buffer.is_empty():
		centre = mouse_pos
		for obj in ComponentManager.obj_list.values():
			if obj.is_mouse_over:
				var item = CopiedItem.new()
				item.copy(obj, centre)
				buffer.append(item)
				id_change_lut[obj.id] = -1
	return centre

func paste(mouse_pos: Vector2):
	var pasted_count = 0
	var wire_count = 0
	for item in buffer:
		var new_id = item.paste(mouse_pos)
		if new_id == -1:
			continue
		id_change_lut[item.old_id] = new_id
		pasted_count += 1
	for item in buffer:
		if not id_change_lut.has(item.old_id):
			continue
		var element = ComponentManager.get_by_id(id_change_lut[item.old_id])
		if element == null:
			continue
		for key in item.connections_with_old_ids:
			for conn in item.connections_with_old_ids[key]:
				if not id_change_lut.has(conn["id"]):
					continue
				var other = ComponentManager.get_by_id(id_change_lut[conn["id"]])
				if other == null:
					continue
				var control_points = conn["control_points"].duplicate(true)
				for i in range(control_points.size()):
					control_points[i] += mouse_pos
				var wire = WireManager._create_wire(element.pin(key), other.pin(conn["index"]), control_points)
				if wire != null:
					var wire_event = WireCreationEvent.new()
					wire_event.initialize(wire)
					HistoryBuffer.register_event(wire_event)
					wire_count += 1
	if pasted_count + wire_count > 0:
		var event = NEventsBuffer.new()
		event.initialize(pasted_count + wire_count, [ComponentCreationEvent, WireCreationEvent])
		HistoryBuffer.register_event(event)

func copied_to_json():
	var json_list_ic: Array = []
	var netlist: Array = []
	var id_map = {}
	var ic_counter = 1
	for ic in buffer:
		json_list_ic.append(ic.to_json_object(ic_counter))
		id_map[ic.old_id] = ic_counter
		ic_counter += 1
	for ic in buffer:
		for conn in ic.connections_with_old_ids:
			for conn_to in ic.connections_with_old_ids[conn]:
				netlist.append({
					"from_ic": id_map[ic.old_id],
					"from_pin": conn,
					"to_ic": id_map[conn_to.id],
					"to_pin": conn_to.index,
					"control_points": conn_to.control_points
				})
	var json = JSON.new()
	return json.stringify({"components":json_list_ic, "netlist": netlist}, '\t')
	
