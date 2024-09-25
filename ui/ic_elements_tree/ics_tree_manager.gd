extends Node

var selected_item: TreeItem

var _name_to_class_path: Dictionary = {}
var _name_to_config_path: Dictionary = {}

func get_selected_element_name(): # Returns String or null
	if ICsTreeManager.selected_item == null: return null
	return ICsTreeManager.selected_item.get_text(0)

func add_class_path(name, config):
	_name_to_class_path[name] = config

func get_class_path(name) -> String:
	return _name_to_class_path[name]


func add_config_path(name, config):
	_name_to_config_path[name] = config

func get_config_path(name) -> String:
	return _name_to_config_path[name]
