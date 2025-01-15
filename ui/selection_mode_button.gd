extends Button

var sel_icon = preload("res://ui/menu_icons/select.png")
var cursor = preload("res://ui/menu_icons/cursor.png")
@onready var camera = get_node("/root/RootNode/Camera2D")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	if not GlobalSettings.is_selecting:
		GlobalSettings.is_selecting = true
		self.tooltip_text = "Режим выделения"
		self.icon = sel_icon
		GlobalSettings.is_selecting = true
		camera.lock_pan = true
	else:
		GlobalSettings.is_selecting = false
		self.tooltip_text = "Обычный режим"
		self.icon = cursor
		GlobalSettings.is_selecting = false
		camera.lock_pan = false
		camera.pressed_mmb = false


func _on_mouse_entered() -> void:
	GlobalSettings.disableGlobalInput = true

func _on_mouse_exited() -> void:
	GlobalSettings.disableGlobalInput = false
