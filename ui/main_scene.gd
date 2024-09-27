extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	NetlistClass.propagate_signal()

func _input(event):
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
		SaveManager.save()
	elif event.is_action_pressed("load_scheme"):
		SaveManager.load(self)
