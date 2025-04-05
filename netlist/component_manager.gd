extends Node
# Component Manager

var obj_list: Dictionary # int -> CircuitComponent

var last_id = 0

var ALL_COMPONENTS_LIST

var selection_area

var deletion_queue: Array[CircuitComponent] = []

func get_config_path_by_name(name:String):
	return ALL_COMPONENTS_LIST[name].config_path

func get_class_path_by_name(name:String):
	return ALL_COMPONENTS_LIST[name].logic_class_path

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

func get_by_id(id: int) -> CircuitComponent:
	return obj_list.get(id)
	
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
	
	
func _ready() -> void:
	var json = JSON.new()
	var file = FileAccess.open("res://components/all_components.json", FileAccess.READ).get_as_text()
	ALL_COMPONENTS_LIST = json.parse_string(file)
	selection_area = get_node("/root/RootNode/SelectionArea")

func toggle_output_highlight():
	for obj in obj_list.values():
		obj.toggle_output_highlight()
