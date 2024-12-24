extends Node2D
var grid_rect
var timer
var memory_viewer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_rect = get_node("GridLayer/GridRect")
	timer = Timer.new() # TODO: This is not good
	timer.one_shot = true
	timer.wait_time = 0.1
	timer.timeout.connect(WireManager.force_update_wires)
	add_child(timer)

	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	NetlistClass.propagate_signal()

func _input(event):
	if (GlobalSettings.disableGlobalInput):
		return
	if event.is_action_pressed("add_new_ic_element"):
		create_selected_element()
	elif event.is_action_pressed("save_scheme"):
		if SaveManager.last_path == "":
			get_node("SaveAsFileDialog")._on_save_as_button_pressed()
		else:
			SaveManager._on_autosave()
	elif event.is_action_pressed("load_scheme"):
		get_node("LoadFileDialog")._on_load_button_pressed()
	elif event.is_action_pressed("undo"):
		HistoryBuffer.undo_last_event()
	elif event.is_action_pressed("redo"):
		HistoryBuffer.redo_last_event()

func toggle_graphics_mode():
	GlobalSettings.LegacyGraphics = not GlobalSettings.LegacyGraphics
	if(!GlobalSettings.LegacyGraphics):
		grid_rect.material.set_shader_parameter("grid_color",Vector4(0.2, 0.2, 0.2, 1.0))
		grid_rect.material.set_shader_parameter("background_color",Vector4(0.4, 0.6, 0.9, 1.0))
		for ic in ComponentManager.obj_list.values():
			ic.change_graphics_mode(GlobalSettings.GraphicsMode.Default) # TODO: Move to componenet manager
	else:
		grid_rect.material.set_shader_parameter("grid_color",Vector4(128.0/256.0, 129.0/256.0, 1/256.0, 1.0))
		grid_rect.material.set_shader_parameter("background_color",Vector4(41.0/256.0, 33.0/256.0, 4/256.0, 1.0))
		for ic in ComponentManager.obj_list.values():
			ic.change_graphics_mode(GlobalSettings.GraphicsMode.Legacy)
	for wire in WireManager.wires:
		wire.change_color()
	timer.start()
	get_node("./GridSprite").visible = not get_node("./GridSprite").visible
	
func create_selected_element():
	var element_name = ICsTreeManager.get_selected_element_name()
	if element_name == null: return
	var spec = ComponentSpecification.new()
	spec.initialize_from_json( ICsTreeManager.get_config_path(element_name) )
	var element: CircuitComponent = load( ICsTreeManager.get_class_path(element_name) ).new()
	element.initialize(spec)
	element.position = get_global_mouse_position()
	element.drag_offset = -element.hitbox.shape.size / 2
	add_child(element)
	element.is_dragged = true
	element.is_mouse_over = true
	get_node("./Camera2D").lock_pan = true
	# TODO: Why do we even register IC`s in their constructor and not there?
	var event = ComponentCreationEvent.new()
	event.initialize(element)
	HistoryBuffer.register_event(event)
