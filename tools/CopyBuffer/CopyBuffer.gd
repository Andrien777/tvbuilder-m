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
	var centre = Vector2.ZERO
	var counter = 0
	for obj: CircuitComponent in ComponentManager.obj_list.values():
		if obj.is_selected:
			centre += obj.position + obj.hitbox.shape.size/2
			counter += 1
	centre /= counter
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
	for item in buffer:
		id_change_lut[item.old_id] = item.paste(mouse_pos)
	for item in buffer:
		var element = ComponentManager.get_by_id(id_change_lut[item.old_id])
		for key in item.connections_with_old_ids:
			for conn in item.connections_with_old_ids[key]:
				var other = ComponentManager.get_by_id(id_change_lut[conn["id"]])
				var control_points = conn["control_points"].duplicate(true)
				for i in range(control_points.size()):
					control_points[i] += mouse_pos
				WireManager._create_wire(element.pin(key), other.pin(conn["index"]), control_points)
	var event = NEventsBuffer.new()
	event.initialize(buffer.size(), [ComponentCreationEvent])
	HistoryBuffer.register_event(event)

func copied_to_json():
	var json_list_ic: Array
	var netlist: Array
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
	
