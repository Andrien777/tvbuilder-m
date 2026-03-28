extends Node
# Component Manager

var obj_list: Dictionary # int -> CircuitComponent

var last_id = 0

var ALL_COMPONENTS_LIST

var selection_area

var deletion_queue: Array[CircuitComponent] = []
var COMPONENT_OVERRIDES = {
	"Группа светодиодов": {
		"config_path": "res://components/ic/other/led_group.json",
		"logic_class_path": "res://components/ic/other/led_group.gd"
	},
	"Группа переключателей": {
		"config_path": "res://components/ic/other/switch_group.json",
		"logic_class_path": "res://components/ic/other/switch_group.gd"
	}
}

func _normalize_component_name(name: String) -> String:
	if COMPONENT_OVERRIDES.has(name):
		return name
	if ALL_COMPONENTS_LIST != null and ALL_COMPONENTS_LIST.has(name):
		return name
	match name:
		"Группа светодиодов X", "Группа светодиодов Х":
			return "Группа светодиодов"
		_:
			return name

func _get_component_entry(name: String):
	var normalized_name = _normalize_component_name(name)
	if COMPONENT_OVERRIDES.has(normalized_name):
		return COMPONENT_OVERRIDES[normalized_name]
	if ALL_COMPONENTS_LIST != null and ALL_COMPONENTS_LIST.has(normalized_name):
		return ALL_COMPONENTS_LIST[normalized_name]
	return null

func get_config_path_by_name(name:String):
	var entry = _get_component_entry(name)
	return entry.config_path if entry != null else null

func get_class_path_by_name(name:String):
	var entry = _get_component_entry(name)
	return entry.logic_class_path if entry != null else null

func create_component_from_state(state: Dictionary) -> CircuitComponent:
	var name = _normalize_component_name(str(state.get("name", "")))
	var entry = _get_component_entry(name)
	if name == "" or entry == null:
		InfoManager.write_error("Failed to create component from state: unknown component %s" % [name])
		return null
	var component: CircuitComponent = load(get_class_path_by_name(name)).new()
	var spec = ComponentSpecification.new()
	spec.initialize_from_json(get_config_path_by_name(name))
	var details = state.get("details", {})
	if details is Dictionary:
		spec.set_details(details)
	component.initialize(spec, state)
	if state.has("position") and state["position"] is Vector2:
		component.position = state["position"]
	return component

func register_object(object: CircuitComponent):
	object.id = int(last_id) # It can become float for some ungodly reason
	last_id += 1
	last_id = int(last_id) # It can become float for some ungodly reason
	if not obj_list.is_empty() and get_by_id(object.id) != null:
		InfoManager.write_error("Попытка добавить объект с повторяющимся id. Объект не будет добавлен")
	else:
		obj_list[object.id] = object

func remove_object(object: CircuitComponent):
	obj_list.erase(object.id)

func add_to_deletion_queue(object: CircuitComponent):
	deletion_queue.append(object)

func clear_deletion_queue():
	for obj in deletion_queue:
		obj.fully_delete()
	if not deletion_queue.is_empty():
		NetlistClass.pause_time()
	deletion_queue.clear()

func _normalize_id(id):
	match typeof(id):
		TYPE_INT:
			return id
		TYPE_FLOAT:
			return int(id)
		TYPE_STRING:
			if String(id).is_valid_int():
				return int(id)
			return null
		_:
			return null

func get_by_id(id) -> CircuitComponent:
	var normalized_id = _normalize_id(id)
	if normalized_id == null:
		return null
	return obj_list.get(normalized_id)
	
func change_id(component: CircuitComponent, new_id: int):
	remove_object(component)
	component.id = new_id
	obj_list[new_id] = component
	
func clear():
	InfoManager.write_info("Поле очищено")
	for comp in obj_list.values():
		comp.queue_free()
	obj_list.clear()
	WireManager.clear()
	NetlistClass.clear()
	ComponentManager.last_id = 0
	SaveManager.do_not_save_ids = []
	GlobalSettings.disableAutosave = false
	GlobalSettings.disableGlobalInput = false
	
	
func _ready() -> void:
	var json = JSON.new()
	var file = FileAccess.open("res://components/all_components.json", FileAccess.READ).get_as_text()
	ALL_COMPONENTS_LIST = json.parse_string(file)
	selection_area = get_node("/root/RootNode/SelectionArea")

func toggle_output_highlight():
	for obj in obj_list.values():
		obj.toggle_output_highlight()
