extends Node2D
var grid_rect
var timer
var memory_viewer
var selection_area
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_rect = get_node("GridLayer/GridRect")
	timer = Timer.new() # TODO: This is not good
	timer.one_shot = true
	timer.wait_time = 0.1
	timer.timeout.connect(WireManager.force_update_wires)
	add_child(timer)
	GlobalSettings.try_load()
	InfoManager.bind_console(get_node("./UiCanvasLayer/ConsoleContainer"))
	InfoManager.bind_indicator(get_node("/root/RootNode/UiCanvasLayer/VBoxContainer2/RibbonContainer/OpenConsoleButton"))
	get_node("./GridSprite").visible = GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode
	get_node("./GridSprite").modulate = GlobalSettings.bg_color
	selection_area = get_node("SelectionArea")
	get_window().title = "TVBuilder - New Project"
	if OS.has_feature("web"):
		Engine.physics_ticks_per_second = 100

func _process(delta: float) -> void:
	if GlobalSettings.is_selecting() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not GlobalSettings.disableGlobalInput:
		if not selection_area.is_tracking:
			selection_area.start_tracking()
	if not GlobalSettings.is_connectivity_mode():
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if GlobalSettings.is_bus_mode() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not GlobalSettings.disableGlobalInput:
		WireManager.register_bus_point(get_global_mouse_position())
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	NetlistClass.process_scheme()
	if GlobalSettings.turbo:
		NetlistClass.process_scheme()
		NetlistClass.process_scheme()

func _exit_tree() -> void:
	GlobalSettings.save()

func _input(event):
	if (GlobalSettings.disableGlobalInput):
		return
	if event.is_action_pressed("add_new_ic_element") and not GlobalSettings.disableGlobalInput:
		create_selected_element()
	elif event.is_action_pressed("save_scheme") and not GlobalSettings.disableGlobalInput:
		if SaveManager.last_path == "":
			get_node("SaveAsFileDialog")._on_save_as_button_pressed()
		else:
			SaveManager._on_autosave()
	elif event.is_action_pressed("load_scheme") and not GlobalSettings.disableGlobalInput:
		get_node("LoadFileDialog")._on_load_button_pressed()
	elif event.is_action_pressed("undo") and not GlobalSettings.disableGlobalInput:
		HistoryBuffer.undo_last_event()
	elif event.is_action_pressed("redo") and not GlobalSettings.disableGlobalInput:
		HistoryBuffer.redo_last_event()
	elif (event.is_action_pressed("abort_wire_creation") or event.is_action_pressed("delete_component")) and not GlobalSettings.disableGlobalInput:
		WireManager.stop_wire_creation()
		if GlobalSettings.is_bus_mode():
			WireManager.finish_current_bus()

	elif event.is_action_pressed("copy") and not GlobalSettings.disableGlobalInput:
		CopyBuffer.copy(get_global_mouse_position())
		selection_area.remember_copy_offset(get_global_mouse_position())
	elif event.is_action_pressed("paste") and not GlobalSettings.disableGlobalInput:
		CopyBuffer.paste(get_global_mouse_position())
		selection_area.paste_copy_offset(get_global_mouse_position())
	elif event.is_action_pressed("select") and not GlobalSettings.disableGlobalInput:
		to_selection_mode()
	elif event.is_action_pressed("normal") and not GlobalSettings.disableGlobalInput:
		to_normal_mode()
	elif event.is_action_pressed("conn_mode") and not GlobalSettings.disableGlobalInput:
		to_connectivity_mode()
	elif event.is_action_pressed("open_history_viewer") and not GlobalSettings.disableGlobalInput:
		$HistoryViewerWindow.visible = not $HistoryViewerWindow.visible
	
	
	# Has to be in a separate if
	if event.is_action_pressed("abort_wire_creation") and not GlobalSettings.disableGlobalInput:
		selection_area.stop_selection()
		print_orphan_nodes()

	elif event.is_action_pressed("create_bus") and not GlobalSettings.disableGlobalInput:
		WireManager.register_bus_point(get_global_mouse_position())
	elif event.is_action_pressed("bus_mode") and not GlobalSettings.disableGlobalInput:
		to_bus_mode()


func toggle_graphics_mode():
	if GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode:
		GlobalSettings.CurrentGraphicsMode = DefaultGraphicsMode
	else:
		GlobalSettings.CurrentGraphicsMode = LegacyGraphicsMode
	if(GlobalSettings.CurrentGraphicsMode==DefaultGraphicsMode):
		grid_rect.material.set_shader_parameter("grid_color",Vector4(0.2, 0.2, 0.2, 1.0))
		grid_rect.material.set_shader_parameter("background_color",Vector4(0.4, 0.6, 0.9, 1.0))
		for ic in ComponentManager.obj_list.values():
			ic.change_graphics_mode(GlobalSettings.CurrentGraphicsMode) # TODO: Move to componenet manager
	else:
		grid_rect.material.set_shader_parameter("grid_color",Vector4(128.0/256.0, 129.0/256.0, 1/256.0, 1.0))
		grid_rect.material.set_shader_parameter("background_color",Vector4(41.0/256.0, 33.0/256.0, 4/256.0, 1.0))
		for ic in ComponentManager.obj_list.values():
			ic.change_graphics_mode(GlobalSettings.CurrentGraphicsMode)
	for wire in WireManager.wires:
		wire.change_color()
	if GlobalSettings.useDefaultWireColor:
		get_node("/root/RootNode/UiCanvasLayer/VBoxContainer2/MenuContainer/SettingsWindow/VBoxContainer/ColorSubmenu/WireColorContainer/WireColorPickerButton")._on_wire_color_reset_button_pressed()
	timer.start()
	get_node("./GridSprite").visible = GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode
	
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

func to_normal_mode():
	GlobalSettings.CursorMode = GlobalSettings.CURSOR_MODES.NORMAL
	get_node("./Camera2D").lock_pan = false
	get_node("./Camera2D").pressed_mmb = false

func to_connectivity_mode():
	GlobalSettings.CursorMode = GlobalSettings.CURSOR_MODES.CONNECTIVITY_MODE
	get_node("./Camera2D").lock_pan = false
	get_node("./Camera2D").pressed_mmb = false

func to_selection_mode():
	GlobalSettings.CursorMode = GlobalSettings.CURSOR_MODES.SELECTION
	get_node("./Camera2D").lock_pan = true

func to_bus_mode():
	GlobalSettings.CursorMode = GlobalSettings.CURSOR_MODES.BUS
	get_node("./Camera2D").lock_pan = false
	get_node("./Camera2D").pressed_mmb = false
	
