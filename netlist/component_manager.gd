extends Node
# Component Manager

var obj_list: Dictionary # int -> CircuitComponent

var last_id = 0

var ALL_COMPONENTS_LIST

var selection_area

func get_config_path_by_name(name:String):
	return ALL_COMPONENTS_LIST[name].config_path

func get_class_path_by_name(name:String):
	return ALL_COMPONENTS_LIST[name].logic_class_path

func register_object(object: CircuitComponent):
	object.id = last_id
	last_id += 1
	if not obj_list.is_empty() and get_by_id(object.id) != null:
		PopupManager.display_error("Попытка добавить дубликат id", "Объект не добавлен", Vector2(100, 100))
		OS.alert("Обнаружено столкновение идентификаторов","Ошибка добавления объекта",)
	else:
		obj_list[object.id] = object

func remove_object(object: CircuitComponent):
	obj_list.erase(object.id)
	
func get_by_id(id: int) -> CircuitComponent:
	return obj_list.get(id)
	
func change_id(component: CircuitComponent, new_id: int):
	remove_object(component)
	component.id = new_id
	obj_list[new_id] = component
	
func clear():
	for comp in obj_list.values():
		comp.queue_free()
	obj_list.clear()
	WireManager.clear()
	NetlistClass.clear()
	ComponentManager.last_id = 0
	
func _ready() -> void:
	var json = JSON.new()
	var file = FileAccess.open("res://components/all_components.json", FileAccess.READ).get_as_text()
	ALL_COMPONENTS_LIST = json.parse_string(file)
	selection_area = get_node("/root/RootNode/SelectionArea")

func toggle_output_highlight():
	for obj in obj_list.values():
		obj.toggle_output_highlight()
