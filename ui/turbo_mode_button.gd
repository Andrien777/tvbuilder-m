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
		Engine.physics_ticks_per_second = max(500, GlobalSettings.tps)
		Engine.max_physics_steps_per_frame = max(9, ceili(GlobalSettings.tps/60))
	else:
		Engine.physics_ticks_per_second = GlobalSettings.tps
		Engine.max_physics_steps_per_frame = ceili(GlobalSettings.tps/60)
