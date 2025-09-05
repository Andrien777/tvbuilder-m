extends AcceptDialog
var file_path: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if FileAccess.file_exists("res://doc/tutorial.htm"):
		var file = FileAccess.open("res://doc/tutorial.htm", FileAccess.READ)
		file_path = file.get_path_absolute()
		file.close()
	else:
		InfoManager.write_error("Не удалось загрузить документацию. Файл не найден.")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_help_button_pressed() -> void:
	if OS. has_feature("web"):
		JavaScriptBridge.eval("window.open('doc/tutorial.htm', '_blank').focus();", true)
		return
	if file_path and FileAccess.file_exists(file_path):
		if OS.get_name() == "Windows":
			OS.shell_open(file_path.replace("/", "\\"))
		else:
			OS.shell_open(file_path)
	else:
		OS.alert("Не удалось открыть документацию. Отсутствуют необходимые ресурсы для загрузки.", "Ошибка")
		InfoManager.write_error("Не удалось загрузить документацию. Файл не найден.")
