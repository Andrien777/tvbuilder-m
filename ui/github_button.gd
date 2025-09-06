extends Button

func _ready() -> void:
	if OS.has_feature("web"):
		visible = false

func _on_pressed() -> void:
	OS.shell_open("https://github.com/Andrien777/tvbuilder-m")
