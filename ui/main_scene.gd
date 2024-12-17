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

	memory_viewer = preload("res://tools/memory_viewer.tscn").instantiate() # I feel like this is not needed anymore?
	add_child(memory_viewer)

	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	NetlistClass.propagate_signal()

func _input(event):
	if (GlobalSettings.disableGlobalInput):
		return
	if event.is_action_pressed("add_new_ic_element"):
		var element_name = ICsTreeManager.get_selected_element_name()
		if element_name == null: return
		
		var spec = ComponentSpecification.new()
		spec.initialize_from_json( ICsTreeManager.get_config_path(element_name) )
		
		var element: CircuitComponent = load( ICsTreeManager.get_class_path(element_name) ).new()
		element.initialize(spec)
		element.position = get_global_mouse_position()
		add_child(element)
	elif event.is_action_pressed("save_scheme"):
		if SaveManager.last_path == "":
			get_node("SaveAsFileDialog").visible = true
		else:
			SaveManager._on_autosave()
	elif event.is_action_pressed("load_scheme"):
		get_node("LoadFileDialog").visible = true
	elif event.is_action_pressed("highlight_level"):
		#GlobalSettings.LevelHighlight = not GlobalSettings.LevelHighlight
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
	elif event.is_action_pressed("toggle_grid"):
			get_node("./GridLayer/GridRect").visible = not get_node("./GridLayer/GridRect").visible

		
