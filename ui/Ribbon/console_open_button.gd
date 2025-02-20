extends Button
@onready var player:AnimationPlayer = $AnimationPlayer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if InfoManager.unread_counter!=0:
		self.text = str(InfoManager.unread_counter)
		
	else:
		self.text = ""


func _on_pressed() -> void:
	if Input.is_key_pressed(KEY_CTRL):
		if InfoManager.console:
			InfoManager.console._on_clear_button_pressed()
			self.text = ""
			InfoManager.unread_counter = 0
	else:
		InfoManager.toggle_console()


func _on_mouse_entered() -> void:
	GlobalSettings.disableGlobalInput = true

func _on_mouse_exited() -> void:
	GlobalSettings.disableGlobalInput = false
