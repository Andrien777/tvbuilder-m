extends Node

class_name CopiedItem

var old_id
var item_name: String
var item_offset: Vector2
var component_state: Dictionary = {}
var connections_with_old_ids = {}

func _canonicalize_component_state(obj: CircuitComponent) -> void:
	if not component_state.has("details") or not (component_state["details"] is Dictionary):
		component_state["details"] = {}
	var details: Dictionary = component_state["details"]
	if obj is LEDGroup or obj is LEDGroupLegacy:
		component_state["name"] = "Группа светодиодов"
		details["size"] = obj.pins.size()
	elif obj is SwitchGroup or obj is SwitchGroupLegacy:
		component_state["name"] = "Группа переключателей"
		details["size"] = obj.pins.size()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func copy(obj: CircuitComponent, mouse_pos: Vector2):
	connections_with_old_ids.clear()
	component_state = obj.to_json_object().duplicate(true)
	_canonicalize_component_state(obj)
	self.item_name = component_state.get("name", obj.readable_name)
	self.item_offset = obj.position - mouse_pos
	self.old_id = obj.id
	for wire in WireManager.wires:
		if wire.first_object in obj.pins and wire.second_object.parent.is_selected:
			var control_points = wire.control_points.duplicate(true)
			for i in range(control_points.size()):
				control_points[i] -= mouse_pos
			if connections_with_old_ids.has(wire.first_object.index):
				connections_with_old_ids[wire.first_object.index].append({"id": wire.second_object.parent.id,"index": wire.second_object.index, "control_points": control_points})
			else:
				connections_with_old_ids[wire.first_object.index] = [{"id": wire.second_object.parent.id,"index": wire.second_object.index, "control_points": control_points}]

func paste(mouse_pos: Vector2):
	if item_name == null: return
	var state = component_state.duplicate(true)
	state["name"] = item_name
	state["position"] = mouse_pos + item_offset
	var element = ComponentManager.create_component_from_state(state)
	if element == null:
		return -1
	ComponentManager.get_node("/root/RootNode").add_child(element)
	var event = ComponentCreationEvent.new()
	event.initialize(element)
	HistoryBuffer.register_event(event)
	return element.id

func to_json_object(new_id = -1):
	var state = component_state.duplicate(true)
	state["id"] = old_id if new_id == -1 else new_id
	state["name"] = item_name
	state["offset"] = item_offset
	state.erase("position")
	return state
