extends Node

var buffer: Array[CopiedItem] = []
var id_change_lut: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func copy(mouse_pos: Vector2):
	buffer.clear()
	for obj in ComponentManager.obj_list.values():
		if obj.is_selected:
			var item = CopiedItem.new()
			item.copy(obj, mouse_pos)
			buffer.append(item)
			id_change_lut[obj.id] = -1
	if buffer.is_empty():
		for obj in ComponentManager.obj_list.values():
			if obj.is_mouse_over:
				var item = CopiedItem.new()
				item.copy(obj, mouse_pos)
				buffer.append(item)
				id_change_lut[obj.id] = -1

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
