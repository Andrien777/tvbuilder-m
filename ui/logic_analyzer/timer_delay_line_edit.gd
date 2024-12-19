extends LineEdit

var delay_value: float = 1

signal delay_value_changed(new_value: float)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = str(delay_value)

func _on_text_submitted(new_text: String) -> void:
	delay_value = float(new_text)
	if delay_value == 0: delay_value = 1
	delay_value_changed.emit(delay_value)

func _on_focus_exited() -> void:
	text = str(delay_value)
	
