extends Button

@onready var logic_analyzer_window = get_node("/root/RootNode/LogicAnalyzerWindow")

func _on_pressed() -> void:
	logic_analyzer_window.visible = true
	logic_analyzer_window.grab_focus()
