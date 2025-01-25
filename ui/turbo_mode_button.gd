extends CheckButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	GlobalSettings.turbo = not GlobalSettings.turbo
	button_pressed = GlobalSettings.turbo
	if GlobalSettings.turbo:
		Engine.physics_ticks_per_second = 500
		Engine.max_physics_steps_per_frame = 9
	else:
		Engine.physics_ticks_per_second = 200
		Engine.max_physics_steps_per_frame = 8
