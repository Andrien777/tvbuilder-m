extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event):
	if event.is_action_pressed("create_debug_object"):
		var spec = ComponentSpecification.new()
		spec.initialize_from_json("res://switch.json")
		var comp = CircuitComponent.new()
		comp.initialize(spec)
		comp.position = get_global_mouse_position()
		add_child(comp)
		#var switch = Switch.new()
		#switch.initialize(spec)
		#switch.position = get_global_mouse_position()
		#add_child(switch)
	
