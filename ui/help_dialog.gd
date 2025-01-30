extends AcceptDialog
var file_path

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var file = FileAccess.open("res://doc/Инструкция по использованию.htm", FileAccess.READ)
	file_path = file.get_path_absolute()
	file.close()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_help_button_pressed() -> void:
	OS.shell_open("file://" + file_path)
