extends Tree

@onready var tree: Tree = $"."

func _ready() -> void:
	_initialize_from_json()

func _initialize_from_json() -> void:
	var json = JSON.new()
	var file = FileAccess.open("res://ui/ic_elements_tree/tree_config.json", FileAccess.READ).get_as_text()
	var parsed = json.parse_string(file)
	
	if "group_name" in parsed:
		_parse_group(parsed, tree.create_item())
	else:
		print("error while parsing res://tree_config.json")
		
func _parse_group(group, tree_node):
	for element in group.subelements:
		var new_child = tree.create_item(tree_node)
		if "group_name" in element:
			new_child.set_text(0, element.group_name)
			_parse_group(element, new_child)
		elif "ic_name" in element:
			new_child.set_text(0, element.ic_name)
			ICsTreeManager.add_config_path(element.ic_name, element.config_path)
			ICsTreeManager.add_class_path(element.ic_name, element.logic_class_path)
			
	 
func _on_item_mouse_selected(mouse_position: Vector2, _mouse_button_index: int) -> void:
	var item = tree.get_item_at_position(mouse_position)
	ICsTreeManager.selected_item = item

func _on_nothing_selected() -> void:
	ICsTreeManager.selected_item = null
