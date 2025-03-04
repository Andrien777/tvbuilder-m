extends Tree

@onready var tree: Tree = $"."
var timer: Timer
var old_mouse_position
var mouse_over = false

func _ready() -> void:
	_initialize_from_json()
	timer = Timer.new() # To check if element is created with drag and drop
	timer.one_shot = true
	timer.wait_time = 0.2
	timer.timeout.connect(_on_timer_callback)
	add_child(timer)

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
			new_child.set_selectable(0, false)
			_parse_group(element, new_child)
		elif "ic_name" in element:
			new_child.set_text(0, element.ic_name)
			ICsTreeManager.add_config_path(element.ic_name, element.config_path)
			ICsTreeManager.add_class_path(element.ic_name, element.logic_class_path)

func _on_item_mouse_selected(mouse_position: Vector2, _mouse_button_index: int) -> void:
	var item = tree.get_item_at_position(mouse_position)
	ICsTreeManager.selected_item = item
	old_mouse_position = get_global_mouse_position()
	timer.start()
	get_node("/root/RootNode").to_normal_mode()
	get_node("/root/RootNode/Camera2D").lock_pan = true

func _on_nothing_selected() -> void:
	ICsTreeManager.selected_item = null
	
func _on_timer_callback():
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		get_node("/root/RootNode").create_selected_element()
	else:
		get_node("/root/RootNode/Camera2D").lock_pan = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("hide_tree") and not GlobalSettings.disableGlobalInput:
		hide_tree()

var tree_visible = true
var tween
func hide_tree():
	if tree_visible:
		if tween:
			tween.kill()
		tween = create_tween()
		tween.tween_property(tree,"scale",Vector2(0, 1),0.4).set_trans(Tween.TRANS_CIRC)
		tree_visible = false
	else:
		if tween:
			tween.kill()
		tween = create_tween()
		tween.tween_property(tree,"scale",Vector2(1, 1),0.4).set_trans(Tween.TRANS_ELASTIC)
		tree_visible = true
var previousGlobalInputState:bool
func _on_mouse_entered() -> void:
	previousGlobalInputState = GlobalSettings.disableGlobalInput
	GlobalSettings.disableGlobalInput = true
	get_node("/root/RootNode/Camera2D").lock_pan = true

func _on_mouse_exited() -> void:
	if timer.is_stopped():
		get_node("/root/RootNode/Camera2D").lock_pan = false
	GlobalSettings.disableGlobalInput = previousGlobalInputState
